import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

/// Mocked UPI-style payment screen.
class PaymentScreen extends StatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _isPaying = false;
  bool _isPaid = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      _isPaying = false;
      _isPaid = true;
    });
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Payment',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: _isPaid ? _buildSuccessView() : _buildPaymentView(),
    );
  }

  Widget _buildPaymentView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Amount display
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Amount to Pay',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.inkLight)),
                const SizedBox(height: 8),
                Text('₹450',
                    style: GoogleFonts.sora(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    )),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildBreakdown('Service charge', '₹425'),
                const SizedBox(height: 6),
                _buildBreakdown('Platform fee (5%)', '₹22'),
                const SizedBox(height: 6),
                _buildBreakdown('Welfare fund (1%)', '₹3',
                    color: AppColors.teal),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: AppColors.teal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPI Payment',
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('user@upi',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.inkLight)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.teal, size: 22),
              ],
            ),
          ),

          const Spacer(flex: 2),

          // Pay button
          PrimaryButton(
            label: 'Pay ₹450',
            isLoading: _isPaying,
            icon: Icons.payment_rounded,
            onPressed: _processPayment,
          ),
          const SizedBox(height: 16),
          Text(
            'This is a demo — no real payment will be processed.',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated success icon
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 70, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 28),
            Text('Payment Successful!',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                )),
            const SizedBox(height: 8),
            Text('₹450 paid to Ramesh Kumar',
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.inkLight)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.volunteer_activism_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹3 contributed to Worker Welfare Fund',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Rate Your Experience',
              icon: Icons.star_rounded,
              onPressed: () {
                context.go('/booking/${widget.bookingId}/rate');
              },
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Back to Home',
              isOutlined: true,
              icon: Icons.home_rounded,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(String label, String amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.inkLight)),
        Text(amount,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.ink,
            )),
      ],
    );
  }
}
