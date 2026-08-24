import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/primary_button.dart';
import '../../services/location_service.dart';

/// Multi-step booking flow: address → date/time → details → confirm.
/// Enhanced with animated transitions and transparent cooperative math breakdown.
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
  String _address = 'Connaught Place, Central Delhi, NCR';
  bool _isDetectingLocation = false;
  String _serviceDetails = '';
  bool _isEmergency = false;
  bool _isBooking = false;
  String? _selectedService;
  String? _workerName;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.service ?? ref.read(selectedServiceProvider);
    _workerName = widget.workerName;

    final activeLoc = ref.read(userLocationStateProvider);
    _address = '${activeLoc.areaName}, ${activeLoc.subDistrict}';

    // Load worker name if workerId is provided
    if (widget.workerId != null) {
      final workers = MockDataService.getMockWorkers();
      final w = workers.where((w) => w.id == widget.workerId).firstOrNull;
      _workerName ??= w?.name;
      if (w != null && _selectedService == null && w.skills.isNotEmpty) {
        _selectedService = w.skills.first;
      }
    }
  }

  Future<void> _autoDetectAddress() async {
    HapticFeedback.lightImpact();
    setState(() => _isDetectingLocation = true);
    try {
      final locService = ref.read(locationServiceProvider);
      final coords = await locService.getCurrentLocation();
      final area = locService.getApproximateArea(coords);
      ref.read(userLocationStateProvider.notifier).setCustomCoordinates(
            coords,
            area,
            'Live GPS (${coords.latitude.toStringAsFixed(3)}, ${coords.longitude.toStringAsFixed(3)})',
          );
      if (mounted) {
        setState(() {
          _address =
              '$area, Lat: ${coords.latitude.toStringAsFixed(3)}, Lng: ${coords.longitude.toStringAsFixed(3)}';
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  double _getBaseServicePrice() {
    final service = _selectedService ?? 'electrician';
    switch (service) {
      case 'electrician':
        return 450.0;
      case 'plumber':
        return 400.0;
      case 'carpenter':
        return 550.0;
      case 'cleaner':
        return 350.0;
      case 'painter':
        return 650.0;
      case 'caregiver':
        return 500.0;
      case 'gardener':
        return 300.0;
      default:
        return 450.0;
    }
  }

  Future<void> _confirmBooking() async {
    HapticFeedback.mediumImpact();
    setState(() => _isBooking = true);

    // Simulate booking creation
    await Future.delayed(const Duration(milliseconds: 900));

    final bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isBooking = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 48, color: AppColors.success),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text('Booking Confirmed!',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  )),
              const SizedBox(height: 8),
              Text(
                'Assigned to ${_workerName ?? "verified cooperative worker"}.\nDispatch route generated in real-time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Track Partner on Live Map',
                icon: Icons.navigation_rounded,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/booking/$bookingId/tracking');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Book a Service',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),

          // Animated Step content
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
                child: _buildCurrentStep(),
              ),
            ),
          ),

          // Bottom action button bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Address', 'Schedule', 'Details', 'Confirm'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < _currentStep
                    ? AppColors.teal
                    : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isActive = stepIndex == _currentStep;
          final isDone = stepIndex < _currentStep;
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? AppColors.teal
                  : isActive
                      ? AppColors.orange
                      : AppColors.bg,
              border: Border.all(
                color:
                    isDone || isActive ? Colors.transparent : AppColors.border,
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.inkMuted,
                      ),
                    ),
            ),
          );
        }),
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
        return const SizedBox();
    }
  }

  Widget _buildAddressStep() {
    return Column(
      key: const ValueKey('address'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Address',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Text('Confirm or change your service location',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight)),
        const SizedBox(height: 20),

        // Address card (auto-filled from GPS)
        GestureDetector(
          onTap: _autoDetectAddress,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detected Location',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _address,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isDetectingLocation)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.my_location_rounded,
                      size: 20, color: AppColors.teal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Manual address input
        TextField(
          decoration: InputDecoration(
            labelText: 'Flat / Street / Landmark',
            hintText: 'e.g. Flat 302, Green Valley Apts',
            prefixIcon: const Icon(Icons.edit_location_alt_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => _address = v.trim());
            }
          },
        ),
        const SizedBox(height: 16),

        // Emergency fast-track toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isEmergency
                ? AppColors.orange.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEmergency ? AppColors.orange : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on_rounded,
                    color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Fast-Track Dispatch',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Nearest available partner dispatched in ~5 mins',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkLight)),
                  ],
                ),
              ),
              Switch(
                value: _isEmergency,
                activeThumbColor: AppColors.orange,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _isEmergency = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return Column(
      key: const ValueKey('schedule'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Schedule',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Text('When do you need the service?',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight)),
        const SizedBox(height: 20),

        // Date picker
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.teal, size: 22),
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
            );
            if (date != null) setState(() => _selectedDate = date);
          },
        ),
        const SizedBox(height: 12),

        // Time picker
        ListTile(
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          tileColor: AppColors.surface,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time_rounded,
                color: AppColors.orange, size: 22),
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
            );
            if (time != null) setState(() => _selectedTime = time);
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Details',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        Text('Tell us what you need',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.inkLight)),
        const SizedBox(height: 20),

        // Service type selector
        if (_selectedService == null) ...[
          Text('Select Service Type',
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockDataService.serviceCategories.map((cat) {
              final isSelected = _selectedService == cat['id'];
              return ChoiceChip(
                label: Text(cat['label']!),
                selected: isSelected,
                onSelected: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedService = v ? cat['id'] : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // Additional details
        TextField(
          maxLines: 4,
          onChanged: (v) => _serviceDetails = v,
          decoration: InputDecoration(
            hintText: 'Describe the issue or requirements in detail...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final basePrice = _getBaseServicePrice();
    final platformFee = basePrice * 0.05; // 5% cooperative ops
    final welfareFund = basePrice * 0.05; // 5% worker social security fund
    final totalPayable = basePrice + platformFee + welfareFund;
    final privateAggregatorDeduction = totalPayable * 0.28; // Private gig apps take ~28%

    return Column(
      key: const ValueKey('confirm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Booking',
            style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        const SizedBox(height: 20),

        // Summary Card with Transparent Cooperative Math
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow('Trade Service',
                  _capitalizeFirst(_selectedService ?? 'Service')),
              const Divider(height: 20),
              if (_workerName != null) ...[
                _buildSummaryRow('Assigned Partner', _workerName!),
                const Divider(height: 20),
              ],
              _buildSummaryRow('Location', _address),
              const Divider(height: 20),
              _buildSummaryRow('Schedule',
                  '${_selectedDate.day}/${_selectedDate.month} at ${_selectedTime.format(context)}'),
              if (_serviceDetails.trim().isNotEmpty) ...[
                const Divider(height: 20),
                _buildSummaryRow('Customer Notes', _serviceDetails.trim(),
                    isSubtle: true),
              ],
              const Divider(height: 20),

              // Detailed Fair Pricing Math
              _buildSummaryRow(
                  'Base Service Amount', '₹${basePrice.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _buildSummaryRow('Platform Ops (5% Fair Cap)',
                  '₹${platformFee.toStringAsFixed(1)}',
                  isSubtle: true),
              const SizedBox(height: 6),
              _buildSummaryRow('Social Security Fund (5%)',
                  '₹${welfareFund.toStringAsFixed(1)}',
                  isSubtle: true, highlightColor: AppColors.teal),
              const Divider(height: 20),
              _buildSummaryRow('Total Transparent Fare',
                  '₹${totalPayable.toStringAsFixed(0)}',
                  isHighlighted: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cooperative Fair Take-Home Comparison Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      size: 20, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    'Cooperative Fair Wage Guarantee',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '• Worker receives 90% direct take-home (₹${basePrice.toStringAsFixed(0)}).\n'
                '• 5% (₹${welfareFund.toStringAsFixed(1)}) is credited directly to their healthcare fund.\n'
                '• Worker earns +₹${privateAggregatorDeduction.toStringAsFixed(0)} more than on private gig platforms.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.inkLight,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlighted = false,
    bool isSubtle = false,
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSubtle ? 12 : 13,
            color: isSubtle ? AppColors.inkMuted : AppColors.inkLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: isHighlighted ? 17 : (isSubtle ? 12 : 14),
              fontWeight:
                  isHighlighted || !isSubtle ? FontWeight.w700 : FontWeight.w500,
              color: highlightColor ??
                  (isHighlighted ? AppColors.teal : AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: PrimaryButton(
                  label: 'Back',
                  isOutlined: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _currentStep--);
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: _currentStep == 3 ? 'Confirm & Book' : 'Continue',
                isLoading: _isBooking,
                icon: _currentStep == 3
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_currentStep < 3) {
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
