import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/count_up_text.dart';
import '../../widgets/skeleton_box.dart';

/// Payment — clean amount hero with CountUpText, UPI/Cash method selector
/// cards and an animated success checkmark that routes onward.
/// Money rules per contract: base price flat + one 5% welfare note.
class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _Method {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Method(this.id, this.title, this.subtitle, this.icon);
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isPaying = false;
  bool _isPaid = false;
  String _selectedMethodId = 'upi';

  static const _methods = [
    _Method('upi', 'UPI', 'Instant & secure', Icons.account_balance_wallet_rounded),
    _Method('card', 'Card', 'Visa / Mastercard / RuPay', Icons.credit_card_rounded),
    _Method('cash', 'Cash after service', 'Pay your partner directly',
        Icons.payments_rounded),
  ];

  @override
  void initState() {
    super.initState();
    // Reflect the created booking; fetch if deep-linked without state.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(activeBookingProvider)?.id != widget.bookingId) {
        try {
          await ref.read(bookingDetailProvider(widget.bookingId).future);
        } catch (_) {
          // surfaced via provider error state
        }
      }
    });
  }

  Future<void> _processPayment() async {
    HapticFeedback.mediumImpact();
    setState(() => _isPaying = true);
    // Local settlement only — no fake endpoints beyond the contract.
    await Future.delayed(const Duration(milliseconds: 1300));
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() {
      _isPaying = false;
      _isPaid = true;
    });
    // Route onwards to rating screen after celebration settles
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      context.go('/booking/${widget.bookingId}/rate');
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(activeBookingProvider) != null &&
            ref.watch(activeBookingProvider)!.id == widget.bookingId
        ? AsyncValue.data(ref.watch(activeBookingProvider)!)
        : ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title:
            Text('Payment', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
      ),
      body: bookingAsync.when(
        // Predictable layout → shimmer skeleton, never a bare spinner.
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SkeletonBox(height: 140, borderRadius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 88, borderRadius: 20),
              SizedBox(height: 12),
              SkeletonBox(height: 56, borderRadius: 20),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 44, color: AppColors.danger),
                const SizedBox(height: 14),
                Text(
                  'Could not load booking details.',
                  style: GoogleFonts.sora(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Go Home',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
        data: (booking) => _isPaid
            ? _buildSuccessView(booking)
            : _buildPaymentView(booking),
      ),
    );
  }

  Widget _buildPaymentView(Booking booking) {
    final price = booking.price;
    final welfare = price * 0.05;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Amount hero ──
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                Text(
                  'Total Amount Payable',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                CountUpText(
                  price,
                  prefix: '₹',
                  style: GoogleFonts.sora(
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_capitalize(booking.serviceType)} service${booking.workerName != null ? ' • ${booking.workerName}' : ''}',
                  style: GoogleFonts.inter(
                      fontSize: 12.5, color: AppColors.inkFaint),
                ),
                const SizedBox(height: 18),
                Divider(color: AppColors.border.withValues(alpha: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        size: 17, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '5% (₹${welfare.toStringAsFixed(0)}) supports worker welfare fund',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fade(duration: 350.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 20),

          // ── Method selector cards ──
          ...List.generate(_methods.length, (i) {
            final m = _methods[i];
            final selected = m.id == _selectedMethodId;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedMethodId = m.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(m.icon, color: AppColors.primary, size: 21),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title,
                              style: GoogleFonts.sora(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text(m.subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2,
                        ),
                        color: selected ? AppColors.primary : Colors.white,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ),
            )
                .animate(delay: (100 + i * 70).ms)
                .fade(duration: 300.ms)
                .slideY(begin: 0.12, end: 0);
          }),

          const SizedBox(height: 16),

          AppButton(
            label:
                'Pay ₹${price.toStringAsFixed(0)}${_methodSuffix(_selectedMethodId)}',
            isLoading: _isPaying,
            icon: Icons.lock_outline_rounded,
            onPressed: _processPayment,
          ).animate(delay: 320.ms).fade(duration: 300.ms),

          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded,
                    size: 14, color: AppColors.inkFaint),
                const SizedBox(width: 6),
                Text(
                  'Cooperative escrow protected settlement',
                  style:
                      GoogleFonts.inter(fontSize: 11.5, color: AppColors.inkFaint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _methodSuffix(String id) => id == 'cash' ? ' (on completion)' : '';

  Widget _buildSuccessView(Booking booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.success.withValues(alpha: 0.16),
                  AppColors.success.withValues(alpha: 0.08),
                ]),
                border: Border.all(color: AppColors.success, width: 3),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 56, color: AppColors.success),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 400.ms,
                )
                .then(delay: 200.ms)
                .shimmer(duration: 900.ms,
                    color: AppColors.success.withValues(alpha: 0.4)),
            const SizedBox(height: 26),
            Text('Payment Successful!',
                style: GoogleFonts.sora(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(
              '₹${booking.price.toStringAsFixed(0)} settled via cooperative escrow.\n'
              '₹${(booking.price * 0.05).toStringAsFixed(1)} credited to the welfare fund.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13.5, color: AppColors.inkSoft, height: 1.55),
            ).animate(delay: 150.ms).fade(duration: 350.ms),
            const SizedBox(height: 30),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'Opening live tracking…',
              style: GoogleFonts.inter(fontSize: 12.5,
                  fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
