import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

/// 3-slide onboarding introducing the cooperative gig platform.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.groups_rounded,
      title: 'Cooperative-Verified Workers',
      subtitle:
          'Every worker is backed by a Labour Cooperative Federation — verified skills, institutional accountability, and fair wages.',
      color: AppColors.teal,
    ),
    _SlideData(
      icon: Icons.savings_rounded,
      title: 'Fair Pricing, No Middleman Tax',
      subtitle:
          'Only 5–10% goes to platform operations — compared to 20–30% on private gig apps. More value for you and the worker.',
      color: AppColors.orange,
    ),
    _SlideData(
      icon: Icons.volunteer_activism_rounded,
      title: 'Built-in Welfare Fund',
      subtitle:
          'Every booking contributes to worker welfare — insurance, healthcare, and retirement benefits administered by the federation.',
      color: AppColors.teal,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onComplete,
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: AppColors.inkLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.teal
                          : AppColors.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: PrimaryButton(
                label: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                icon: _currentPage == _slides.length - 1
                    ? Icons.arrow_forward_rounded
                    : null,
                onPressed: () {
                  if (_currentPage == _slides.length - 1) {
                    widget.onComplete();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: slide.color),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.inkLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
