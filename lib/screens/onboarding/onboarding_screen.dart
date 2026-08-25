import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';

/// Splash/onboarding — dark gradient hero (#0B1220 → #111A2C) with an
/// animated logo reveal and staggered tagline per DESIGN_SPEC.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _SlideData {
  final IconData icon;
  final List<Color> mesh;
  final String title;
  final String subtitle;

  const _SlideData({
    required this.icon,
    required this.mesh,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.groups_rounded,
      mesh: [Color(0xFF6A5AE0), Color(0xFF9B8CFF)],
      title: 'Cooperative-Verified Workers',
      subtitle:
          'Every worker is backed by a Labour Cooperative Federation — verified skills, institutional accountability, fair wages.',
    ),
    _SlideData(
      icon: Icons.savings_rounded,
      mesh: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
      title: 'Fair Pricing, No Middleman Tax',
      subtitle:
          'A single 5% welfare contribution — compared to 20–30% take-rates on private gig apps.',
    ),
    _SlideData(
      icon: Icons.volunteer_activism_rounded,
      mesh: [Color(0xFF10B981), Color(0xFF6EE7B7)],
      title: 'Built-in Welfare Fund',
      subtitle:
          'Every booking contributes to worker welfare — insurance, healthcare, and pensions run by the federation.',
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle decorative glow
              Positioned(
                top: -120,
                right: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryLight.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: widget.onComplete,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _currentPage == index
                            ? _buildSlide(_slides[index])
                            : const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Dots
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
                                ? AppColors.amber
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: AppButton(
                      label: _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
                      isAmber: true,
                      onPressed: () {
                        HapticFeedback.lightImpact();
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo mark — animated reveal only on first slide
          if (_currentPage == 0)
            _buildLogo()
          else
            const SizedBox(height: 96),

          const SizedBox(height: 48),

          // Icon tile
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: slide.mesh,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.mesh.first.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 52, color: Colors.white),
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 350.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 700.ms,
              ),

          const SizedBox(height: 40),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          )
              .animate(delay: 220.ms)
              .fade(duration: 350.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),

          const SizedBox(height: 14),

          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          )
              .animate(delay: 300.ms)
              .fade(duration: 350.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.handshake_rounded,
              size: 34, color: Colors.white),
        )
            .animate()
            .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1, 1),
              curve: Curves.elasticOut,
              duration: 800.ms,
            )
            .fadeIn(duration: 250.ms),
        const SizedBox(height: 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            children: [
              const TextSpan(text: 'Saha'),
              TextSpan(
                text: 'Karya',
                style: TextStyle(color: AppColors.amber),
              ),
            ],
          ),
        )
            .animate(delay: 150.ms)
            .fade(duration: 300.ms)
            .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
        Text(
          'Cooperative services. Fair dignity.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
        ).animate(delay: 260.ms).fade(duration: 300.ms),
      ],
    );
  }
}
