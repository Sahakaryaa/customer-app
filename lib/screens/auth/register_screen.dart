import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../providers/auth_provider.dart';

/// Registration screen — phone, name, OTP mock.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent! (Demo: use any 6-digit code)')),
    );
  }

  Future<void> _register() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit OTP')),
      );
      return;
    }

    await ref.read(authProvider.notifier).register(
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim(),
          password: _otpController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

              // Header
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
                    Icons.person_add_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Center(
                child: Text(
                  'Create Account',
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
                  'Join the cooperative services network',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.inkLight,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Name
              Text(
                'Full Name',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Phone
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
                decoration: const InputDecoration(
                  hintText: 'Enter 10-digit mobile number',
                  prefixIcon: Padding(
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
              ],
              const SizedBox(height: 24),

              PrimaryButton(
                label: _otpSent ? 'Verify & Register' : 'Send OTP',
                isLoading: authState.isLoading,
                icon: _otpSent ? Icons.verified_user_rounded : Icons.sms_rounded,
                onPressed: _otpSent ? _register : _sendOtp,
              ),
              const SizedBox(height: 20),

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.inkLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(
                        'Login',
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
            ],
          ),
        ),
      ),
    );
  }
}
