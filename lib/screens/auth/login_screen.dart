import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_card.dart';

/// Login — dark gradient header + glass form card.
/// Phone + password (min 4 chars); sent directly as `password` per contract.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters')),
      );
      return;
    }

    await ref.read(authProvider.notifier).login(
          phone: phone,
          password: password,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient hero header ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(Icons.handshake_rounded,
                                size: 24, color: Colors.white),
                          ).animate().scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutCubic,
                                duration: 350.ms,
                              ),
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.sora(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: 'Saha'),
                                TextSpan(
                                    text: 'Karya',
                                    style:
                                        TextStyle(color: AppColors.amber)),
                              ],
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fade(duration: 300.ms)
                          .slideY(begin: -0.2, end: 0),
                      const SizedBox(height: 34),
                      Text(
                        'Welcome back 👋',
                        style: GoogleFonts.sora(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ).animate(delay: 100.ms).fade(duration: 350.ms).slideY(
                          begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                      const SizedBox(height: 8),
                      Text(
                        'Login to book cooperative-verified services.',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          color: Colors.white70,
                        ),
                      ).animate(delay: 180.ms).fade(duration: 350.ms).slideY(
                          begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              ),
            ),

            // ── Glass form card overlapping the header ──
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  opacity: 0.9,
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Phone Number'),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          enabled: !authState.isLoading,
                          decoration: InputDecoration(
                            hintText: 'Enter 10-digit mobile number',
                            counterText: '',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('+91',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(width: 8),
                                  SizedBox(
                                    height: 24,
                                    child: VerticalDivider(
                                        color: AppColors.border, thickness: 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate(delay: 260.ms).fade(duration: 320.ms).slideY(
                            begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                        const SizedBox(height: 18),
                        _fieldLabel('Password'),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          enabled: !authState.isLoading,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            hintText: 'Min 4 characters',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.inkFaint,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ).animate(delay: 330.ms).fade(duration: 320.ms).slideY(
                            begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                        const SizedBox(height: 26),
                        AppButton(
                          label: 'Login',
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading ? null : _login,
                        ).animate(delay: 400.ms).fade(duration: 320.ms),

                        const SizedBox(height: 14),

                        // ── 1-Tap Quick Demo Mode button ──
                        AppButton(
                          label: '🚀 Explore in Demo Mode',
                          isAmber: true,
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading
                              ? null
                              : () async {
                                  await ref
                                      .read(authProvider.notifier)
                                      .loginAsDemo();
                                },
                        ).animate(delay: 440.ms).fade(duration: 320.ms),

                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Instant mock access without backend server',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: Text(
                                  'Register',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate(delay: 480.ms).fade(duration: 320.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
