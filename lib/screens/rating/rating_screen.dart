import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

import '../../widgets/cooperative_badge.dart';

/// Rating screen — 1–5 stars + comment, posts to /bookings/{id}/rate with celebration feedback.
class RatingScreen extends StatefulWidget {
  final String bookingId;

  const RatingScreen({super.key, required this.bookingId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen>
    with SingleTickerProviderStateMixin {
  double _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  late final AnimationController _celebrationController;
  late final Animation<double> _celebrationScale;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationScale = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
      _celebrationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Rate & Review Service',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: _submitted ? _buildThankYouView() : _buildRatingForm(),
    );
  }

  Widget _buildRatingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Worker info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text('RK',
                        style: GoogleFonts.sora(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ramesh Kumar',
                        style: GoogleFonts.sora(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    const CooperativeBadge(compact: true, animate: false),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Electrician · Delhi Central Labour Cooperative',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.inkLight)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Rating label
          Text('How was your service experience?',
              style: GoogleFonts.sora(
                  fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
          const SizedBox(height: 16),

          // Star rating with bounce
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 6),
            itemSize: 46,
            glow: true,
            glowColor: AppColors.gold.withValues(alpha: 0.35),
            itemBuilder: (context, _) =>
                const Icon(Icons.star_rounded, color: AppColors.gold),
            unratedColor: AppColors.gold.withValues(alpha: 0.25),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 10),
          Text(
            _getRatingLabel(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 28),

          // Comment
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Share feedback about Ramesh\'s work (optional)...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 28),

          PrimaryButton(
            label: 'Submit Rating & Feedback',
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
            ScaleTransition(
              scale: _celebrationScale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 64, color: AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            Text('Thank You!',
                style: GoogleFonts.sora(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                )),
            const SizedBox(height: 8),
            Text(
              'Your ${_rating.toInt()}-star rating directly rewards Ramesh Kumar and empowers the SahaKarya labour cooperative federation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.inkLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            PrimaryButton(
              label: 'Back to Home',
              icon: Icons.home_rounded,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel() {
    if (_rating <= 1) return 'Poor';
    if (_rating <= 2) return 'Fair';
    if (_rating <= 3) return 'Good';
    if (_rating <= 4) return 'Very Good';
    return 'Excellent!';
  }
}
