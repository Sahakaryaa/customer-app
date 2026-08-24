import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/nearby_workers_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/primary_button.dart';

import '../../services/location_service.dart';

/// Multi-step booking flow: address → date/time → details → confirm.
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
          _address = '$area, Lat: ${coords.latitude.toStringAsFixed(3)}, Lng: ${coords.longitude.toStringAsFixed(3)}';
          _isDetectingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);

    // Simulate booking creation
    await Future.delayed(const Duration(milliseconds: 1000));

    final bookingId = 'b_${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _isBooking = false);

    if (mounted) {
      // Show success and navigate to tracking
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 44, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text('Booking Confirmed!',
                  style: GoogleFonts.sora(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  )),
              const SizedBox(height: 8),
              Text(
                'Finding a cooperative-verified worker near you...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Track Booking',
                icon: Icons.location_on_rounded,
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

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ),

          // Bottom buttons
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['Address', 'Schedule', 'Details', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: i ~/ 2 < _currentStep ? AppColors.teal : AppColors.border,
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
                color: isDone || isActive ? Colors.transparent : AppColors.border,
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
                fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isDetectingLocation
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.teal,
                          ),
                        )
                      : const Icon(Icons.my_location_rounded,
                          color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service GPS Location (Tap to Refresh)',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_address,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
                const Icon(Icons.refresh_rounded, size: 20, color: AppColors.teal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Emergency toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isEmergency
                ? AppColors.orange.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isEmergency ? AppColors.orange : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.flash_on_rounded,
                  color: _isEmergency ? AppColors.orange : AppColors.inkMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Booking',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('Get a worker within minutes',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.inkLight)),
                  ],
                ),
              ),
              Switch(
                value: _isEmergency,
                activeThumbColor: AppColors.orange,
                onChanged: (v) => setState(() => _isEmergency = v),
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
        Text('Schedule',
            style: GoogleFonts.sora(
                fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
                fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
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
            hintText: 'Describe the work needed (e.g., "Fix leaking tap in kitchen bathroom")',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final priceRange = MockDataService.getEstimatedPrice(
        _selectedService ?? 'electrician');

    return Column(
      key: const ValueKey('confirm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Booking',
            style: GoogleFonts.sora(
                fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 20),

        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Service',
                  _capitalizeFirst(_selectedService ?? 'Service')),
              const Divider(height: 20),
              if (_workerName != null) ...[
                _buildSummaryRow('Worker', _workerName!),
                const Divider(height: 20),
              ],
              _buildSummaryRow('Address', _address),
              const Divider(height: 20),
              _buildSummaryRow('Date',
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              const Divider(height: 20),
              _buildSummaryRow('Time', _selectedTime.format(context)),
              if (_isEmergency) ...[
                const Divider(height: 20),
                _buildSummaryRow('Type', 'Emergency (Priority)'),
              ],
              if (_serviceDetails.trim().isNotEmpty) ...[
                const Divider(height: 20),
                _buildSummaryRow('Notes', _serviceDetails.trim()),
              ],
              const Divider(height: 20),
              _buildSummaryRow('Estimated Price', priceRange,
                  isHighlighted: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Fair pricing note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 18, color: AppColors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only 5–10% platform fee — no hidden charges. '
                  'Workers keep more of what they earn.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.teal,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkLight)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? AppColors.teal : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: PrimaryButton(
                label: 'Back',
                isOutlined: true,
                icon: Icons.arrow_back_rounded,
                onPressed: () => setState(() => _currentStep--),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: PrimaryButton(
              label: _currentStep == 3 ? 'Confirm Booking' : 'Continue',
              isLoading: _isBooking,
              icon: _currentStep == 3
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: () {
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
    );
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
