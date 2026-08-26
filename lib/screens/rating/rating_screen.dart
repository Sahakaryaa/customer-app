import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart' show useMockData;
import '../../services/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/avatar_badge.dart';

/// Rating — big interactive star row (animated scale on select), comment
/// box, submit wired to POST /bookings/{id}/rate; 409 handled gracefully.
class RatingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  String get _workerName =>
      ref.watch(activeBookingProvider)?.workerName ?? 'your partner';

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.rateBooking(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is BookingAlreadyRatedException) {
        AppSnackBar.show(context,
            'Already rated — thanks for the feedback!',
            type: SnackType.info);
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
        return;
      }
      if (useMockData || ApiClient.isConnectionError(e)) {
        // Demo / offline fallback: treat as submitted with gratitude
        HapticFeedback.heavyImpact();
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
        return;
      }
      // Real failure (booking not completed, server error…) — surface it.
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.show(context, ApiClient.friendlyError(e),
          type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Rate Your Experience',
            style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
      ),
      body: _submitted ? _buildThankYouView() : _buildRatingForm(),
    );
  }

  Widget _buildRatingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Worker card
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
                AvatarBadge(name: _workerName, size: 64),
                const SizedBox(height: 12),
                Text(_workerName,
                    style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Cooperative-verified service partner',
                    style: GoogleFonts.inter(
                        fontSize: 12.5, color: AppColors.inkSoft)),
              ],
            ),
          ).animate().fade(duration: 320.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 30),

          Text('How was your service experience?',
              style: GoogleFonts.sora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 20),

          // Big interactive star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final selected = i < _rating;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rating = i + 1);
                },
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.86,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 52,
                      color: selected
                          ? AppColors.warning
                          : AppColors.surfaceAlt,
                      shadows: selected
                          ? [
                              Shadow(
                                  color: AppColors.warning
                                      .withValues(alpha: 0.45),
                                  blurRadius: 16)
                            ]
                          : null,
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: 60 * i))
                    .fade(duration: 260.ms)
                    .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutCubic,
                        duration: 350.ms),
              );
            }),
          ),

          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _ratingLabel(_rating),
              key: ValueKey(_rating),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 26),

          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText:
                  "Share feedback about $_workerName's work (optional)…",
              alignLabelWithHint: true,
              counterText: '',
            ),
          ).animate(delay: 150.ms).fade(duration: 320.ms),

          const SizedBox(height: 26),

          AppButton(
            label: 'Submit Rating',
            isLoading: _isSubmitting,
            icon: Icons.send_rounded,
            onPressed: _submitRating,
          ),
        ],
      ),
    );
  }

  Widget _buildThankYouView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.success.withValues(alpha: 0.16),
                  AppColors.success.withValues(alpha: 0.06),
                ]),
                border:
                    Border.all(color: AppColors.success, width: 3),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 60, color: AppColors.success),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 400.ms,
                )
                .then(delay: 250.ms)
                .shimmer(
                    duration: 900.ms,
                    color: AppColors.success.withValues(alpha: 0.35)),

            // Celebration stars burst
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 26,
                  color: i < _rating
                      ? AppColors.warning
                      : AppColors.surfaceAlt,
                )
                    .animate(delay: Duration(milliseconds: 120 + 90 * i))
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 350.ms,
                    ),
              ),
            ),

            const SizedBox(height: 22),
            Text('Thank You!',
                style: GoogleFonts.sora(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(
              'Your ${_rating.toInt()}-star rating directly rewards '
              '$_workerName and strengthens the cooperative federation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.inkSoft, height: 1.55),
            ).animate(delay: 200.ms).fade(duration: 350.ms),

            const SizedBox(height: 36),
            AppButton(
              label: 'Go to Booking History',
              icon: Icons.history_rounded,
              onPressed: () => context.go('/history'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Back to Home',
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    if (r <= 1) return 'Poor';
    if (r == 2) return 'Fair';
    if (r == 3) return 'Good';
    if (r == 4) return 'Very Good';
    return 'Excellent!';
  }
}
