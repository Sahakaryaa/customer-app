import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../providers/booking_provider.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import '../home/home_screen.dart' show ServiceCategoryIcons;
import '../../widgets/app_button.dart';
import '../../widgets/app_tiles.dart';
import '../../widgets/app_snack_bar.dart';

/// Multi-step booking flow — animated stepper, mesh-gradient service cards,
/// drag-pin mini-map picker, and a flat price panel (single 5% welfare note).
/// Confirm creates a REAL booking via POST /bookings.
class BookingFlowScreen extends ConsumerStatefulWidget {
  final String? workerId;
  final String? service;
  final String? workerName;

  const BookingFlowScreen({
    super.key,
    this.workerId,
    this.service,
    this.workerName,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _currentStep = 0;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  late String _address;
  bool _isDetectingLocation = false;
  String _serviceDetails = '';
  LatLng _pickedLocation = LocationService.defaultLocation;

  @override
  void initState() {
    super.initState();
    final activeLoc = ref.read(userLocationStateProvider);
    _address = activeLoc.areaName;
    _pickedLocation = activeLoc.coordinates;
  }

  String? get _effectiveService {
    if (widget.service != null) return widget.service;
    return ref.read(selectedServiceProvider);
  }

  Future<void> _useCurrentLocation() async {
    HapticFeedback.lightImpact();
    setState(() => _isDetectingLocation = true);
    try {
      final locService = ref.read(locationServiceProvider);
      final result =
          await locService.resolveLocation(showExplainer: false);
      ref.read(userLocationStateProvider.notifier).setCustomCoordinates(
            result.coords,
            result.areaLabel,
            result.sourceLabel,
          );
      if (mounted) {
        setState(() {
          _address = result.areaLabel;
          _pickedLocation = result.coords;
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  double get _basePrice =>
      MockDataService.basePrice(_effectiveService ?? 'electrician');

  Future<void> _confirmBooking() async {
    HapticFeedback.mediumImpact();
    final serviceType = _effectiveService ?? 'electrician';

    // Fold schedule preference into description (contract has no scheduled_time).
    var description = _serviceDetails.trim();
    final scheduleNote =
        'Preferred: ${_selectedDate.day}/${_selectedDate.month} at ${_selectedTime.format(context)}';
    description = description.isEmpty
        ? scheduleNote
        : '$description\n$scheduleNote';

    final params = NewBookingParams(
      serviceType: serviceType,
      price: _basePrice,
      lat: _pickedLocation.latitude,
      lng: _pickedLocation.longitude,
      description: description,
      address: _address,
      // Direct hire — pin the booking to the worker chosen on the profile/map card.
      workerId: widget.workerId,
    );

    final ok = await ref.read(bookingCreationProvider.notifier).create(params);

    if (!mounted) return;

    if (!ok) {
      final err = ref.read(bookingCreationProvider);
      final message = err.hasError
          ? ApiClient.friendlyError(err.error!)
          : 'Could not create your booking.';
      showDialog(
        context: context,
        builder: (ctx) => _errorDialog(message),
      );
      return;
    }

    final booking = ref.read(bookingCreationProvider).valueOrNull;
    if (booking != null) {
      ref.read(activeBookingProvider.notifier).state = booking;
      AppSnackBar.show(context, 'Booking created — choose payment',
          type: SnackType.success);
      context.go('/booking/${booking.id}/payment');
    }
  }

  Widget _errorDialog(String message) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 10),
          Text('Booking failed',
              style: GoogleFonts.sora(fontSize: 17)),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _confirmBooking();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(bookingCreationProvider);
    final isBooking = creationState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Book a Service',
            style:
                GoogleFonts.sora(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey('step_$_currentStep'),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
          _buildBottomBar(isBooking),
        ],
      ),
    );
  }

  // ── Animated progress stepper ──
  Widget _buildStepper() {
    const steps = ['Address', 'Schedule', 'Details', 'Confirm'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_currentStep + 1) / steps.length),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final done = i < _currentStep;
              final active = i == _currentStep;
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight:
                      active || done ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? AppColors.primary
                      : done
                          ? AppColors.ink
                          : AppColors.inkFaint,
                ),
                child: Text(steps[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildScheduleStep();
      case 2:
        return _buildDetailsStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: address + drag-pin mini-map ──
  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Address',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Pin it exactly or use your current location.',
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.inkSoft)),
        const SizedBox(height: 18),

        // Fixed current-location chip
        GestureDetector(
          onTap: _useCurrentLocation,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: _isDetectingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 17),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use current location',
                          style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text(_address,
                          style: GoogleFonts.inter(
                              fontSize: 12.5, color: AppColors.inkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Drag-pin mini-map
        SizedBox(
          height: 190,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _pickedLocation,
                    initialZoom: 14.5,
                    minZoom: 11,
                    maxZoom: 18,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture) {
                        setState(() => _pickedLocation = pos.center);
                      }
                    },
                  ),
                  children: [
                    AppTiles.voyager(),
                    AppTiles.attribution(),
                  ],
                ),
                Center(
                  child: IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, 26),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.warning,
                              border: Border.all(
                                  color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pickedLocation.latitude.toStringAsFixed(4)}, '
                      '${_pickedLocation.longitude.toStringAsFixed(4)}',
                      style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          onChanged: (v) => setState(() => _address = v.trim().isEmpty
              ? 'Pinned location'
              : v.trim()),
          decoration: const InputDecoration(
            labelText: 'Flat / Street / Landmark (optional)',
            hintText: 'e.g. Flat 302, Green Valley Apartments',
            prefixIcon: Icon(Icons.edit_location_alt_rounded, size: 20),
          ),
        ),
      ],
    );
  }

  // ── Step 1: schedule ──
  Widget _buildScheduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Schedule',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('When do you need the service?',
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.inkSoft)),
        const SizedBox(height: 18),

        ListTile(
          contentPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 20),
          ),
          title: const Text('Date'),
          subtitle: Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            HapticFeedback.lightImpact();
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              builder: (context, child) => Theme(
                data: Theme.of(context)
                    .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                child: child!,
              ),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
        const SizedBox(height: 12),

        ListTile(
          contentPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.access_time_rounded,
                color: AppColors.warning, size: 20),
          ),
          title: const Text('Time'),
          subtitle: Text(
            _selectedTime.format(context),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            HapticFeedback.lightImpact();
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
              builder: (context, child) => Theme(
                data: Theme.of(context)
                    .copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                child: child!,
              ),
            );
            if (time != null) setState(() => _selectedTime = time);
          },
        ),
      ],
    );
  }

  // ── Step 2: details + service selection ──
  Widget _buildDetailsStep() {
    final selectedService = _effectiveService;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Details',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Tell us what you need',
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.inkSoft)),
        const SizedBox(height: 18),

        Text('Select Service Type',
            style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(MockDataService.serviceCategories.length,
              (index) {
            final cat = MockDataService.serviceCategories[index];
            final isSelected = selectedService == cat['id'];
            final mesh = AppColors
                .meshGradients[index % AppColors.meshGradients.length];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(selectedServiceProvider.notifier).state = cat['id'];
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.09)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mesh-gradient icon tile
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(colors: mesh),
                      ),
                      child: Icon(
                        ServiceCategoryIcons.forId(cat['id']!),
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        TextField(
          maxLines: 4,
          onChanged: (v) => _serviceDetails = v,
          decoration: const InputDecoration(
            hintText:
                'Describe the issue or requirements in detail…',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // ── Step 3: confirm + flat price panel ──
  Widget _buildConfirmStep() {
    final basePrice = _basePrice;
    final workerName = widget.workerName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Booking',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.ink)),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _summaryRow('Trade Service',
                  _capitalizeFirst(_effectiveService ?? 'Service')),
              const Divider(height: 20),
              if (workerName != null) ...[
                _summaryRow('Assigned Partner', workerName),
                const Divider(height: 20),
              ],
              _summaryRow('Location', _address),
              const Divider(height: 20),
              _summaryRow(
                  'Schedule',
                  '${_selectedDate.day}/${_selectedDate.month} at '
                  '${_selectedTime.format(context)}'),
              if (_serviceDetails.trim().isNotEmpty) ...[
                const Divider(height: 20),
                _summaryRow('Notes', _serviceDetails.trim(), subtle: true),
              ],
              const Divider(height: 20),
              _summaryRow('Base Service Price', '₹${basePrice.toStringAsFixed(0)}',
                  highlighted: true),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Single welfare note per contract money rules.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.success.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded,
                  size: 19, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You pay ₹${basePrice.toStringAsFixed(0)}. "
                  "5% supports the worker welfare fund — no hidden platform fees.",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool highlighted = false, bool subtle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: subtle ? 12 : 13,
              color: subtle ? AppColors.inkFaint : AppColors.inkSoft,
            )),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: highlighted ? 17 : (subtle ? 12 : 14),
              fontWeight: FontWeight.w700,
              letterSpacing: highlighted ? -0.4 : 0,
              color: highlighted ? AppColors.primary : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isBooking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: AppButton(
                  label: 'Back',
                  isOutlined: true,
                  onPressed: () =>
                      setState(() => _currentStep--),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: AppButton(
                label: _currentStep == 3
                    ? 'Confirm & Book'
                    : 'Continue',
                isLoading: isBooking,
                icon: _currentStep == 3
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: isBooking
                    ? null
                    : () {
                        if (_currentStep < 3) {
                          HapticFeedback.lightImpact();
                          setState(() => _currentStep++);
                        } else {
                          _confirmBooking();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
