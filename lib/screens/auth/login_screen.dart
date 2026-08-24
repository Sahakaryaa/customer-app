import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

/// Login screen with phone + OTP (mocked).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    // Mock OTP send — no real SMS gateway needed
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent! (Demo: use any 6-digit code)')),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    // OTP mock — accept any 6-digit code
    await ref.read(authProvider.notifier).login(
          phone: _phoneController.text.trim(),
          password: _otpController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Show error if any
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo / Header
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Center(
                child: Text(
                  'Welcome Back',
                  style: GoogleFonts.sora(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Login to book cooperative-verified services',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.inkLight,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Phone input
              Text(
                'Phone Number',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !_otpSent,
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit mobile number',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🇮🇳 +91',
                            style: TextStyle(fontSize: 14, color: AppColors.ink)),
                        SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: VerticalDivider(
                            color: AppColors.border,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  counterText: '',
                ),
              ),

              if (_otpSent) ...[
                const SizedBox(height: 20),

                // OTP input
                Text(
                  'Enter OTP',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter 6-digit OTP',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent! (Demo mode)')),
                      );
                    },
                    child: const Text('Resend OTP'),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Submit button
              PrimaryButton(
                label: _otpSent ? 'Verify & Login' : 'Send OTP',
                isLoading: authState.isLoading,
                icon: _otpSent ? Icons.login_rounded : Icons.sms_rounded,
                onPressed: _otpSent ? _verifyOtp : _sendOtp,
              ),
              const SizedBox(height: 20),

              // Register link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.inkLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to register — handled by go_router
                        Navigator.of(context).pushReplacementNamed('/register');
                      },
                      child: Text(
                        'Register',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Demo hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.goldDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo mode: Any 10-digit phone & 6-digit OTP will work.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
