import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

/// Transparent UPI-style payment screen with live cooperative breakdown.
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

  // Transparent pricing model: Base ₹450 + 5% Ops + 5% Welfare Fund
  final double _baseAmount = 450.0;
  double get _platformFee => _baseAmount * 0.05;
  double get _welfareFund => _baseAmount * 0.05;
  double get _totalAmount => _baseAmount + _platformFee + _welfareFund;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    HapticFeedback.mediumImpact();
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    HapticFeedback.heavyImpact();
    if (mounted) {
      setState(() {
        _isPaying = false;
        _isPaid = true;
      });
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Payment & Settlement',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: _isPaid ? _buildSuccessView() : _buildPaymentView(),
    );
  }

  Widget _buildPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Amount & Transparent Receipt Display
          Container(
            padding: const EdgeInsets.all(24),
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
                Text(
                  'Total Amount Payable',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.sora(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Transparent Breakdown
                _buildBreakdown('Worker Service Charge (90%)',
                    '₹${_baseAmount.toStringAsFixed(0)}',
                    isBold: true),
                const SizedBox(height: 8),
                _buildBreakdown('Cooperative Platform Ops (5%)',
                    '₹${_platformFee.toStringAsFixed(1)}',
                    color: AppColors.inkLight),
                const SizedBox(height: 8),
                _buildBreakdown('Social Security Fund (5%)',
                    '₹${_welfareFund.toStringAsFixed(1)}',
                    color: AppColors.teal, isBold: true),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 16),

          // Fair-Wage Comparison Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.teal, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% of the ₹${_baseAmount.toStringAsFixed(0)} service amount goes directly to your service partner with ₹${_welfareFund.toStringAsFixed(1)} credited to their pension/medical fund.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.teal,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mock UPI Payment Method Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: AppColors.teal, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UPI Direct Settlement',
                          style: GoogleFonts.sora(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('instant transfer to cooperative escrow',
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

          const SizedBox(height: 32),

          // Pay button
          PrimaryButton(
            label: 'Pay ₹${_totalAmount.toStringAsFixed(0)} via UPI',
            isLoading: _isPaying,
            icon: Icons.lock_outline_rounded,
            onPressed: _processPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment Successful!',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                )),
            const SizedBox(height: 8),
            Text(
              '₹${_totalAmount.toStringAsFixed(0)} settled instantly.\n₹${_baseAmount.toStringAsFixed(0)} transferred to worker escrow.\n+₹${_welfareFund.toStringAsFixed(1)} added to Federation Welfare Fund.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            PrimaryButton(
              label: 'Rate Service Experience',
              icon: Icons.star_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/booking/${widget.bookingId}/rate');
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/home');
              },
              child: Text(
                'Back to Home',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(String label, String value,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: color ?? AppColors.inkLight,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            )),
        Text(value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? AppColors.ink,
            )),
      ],
    );
  }
}
