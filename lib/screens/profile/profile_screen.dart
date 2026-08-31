import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/legal_policy_sheet.dart';

/// User profile — gradient header card, menu, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title:
            Text('Profile', style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkStart.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  AvatarBadge(name: user?.name ?? 'U', size: 76),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Customer',
                    style: GoogleFonts.sora(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.phone ?? '',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: Colors.white70)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text('Cooperative Member',
                        style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber)),
                  ),
                ],
              ),
            ).animate().fade(duration: 320.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: 18),

            _menuItem(context,
                icon: Icons.history_rounded,
                label: 'Booking History',
                onTap: () => context.push('/history')),
            _menuItem(context,
                icon: Icons.location_on_outlined,
                label: 'Saved Addresses',
                subtitle: 'Coming soon',
                onTap: () {}),
            _menuItem(context,
                icon: Icons.language_rounded,
                label: 'Language',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('English',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                onTap: () {}),
            _menuItem(context,
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                subtitle: 'Non-extractable data protection',
                onTap: () => LegalPolicySheet.show(context,
                    doc: LegalDocType.privacyPolicy)),
            _menuItem(context,
                icon: Icons.gavel_rounded,
                label: 'Terms of Service',
                subtitle: 'Fair pricing & cancellation rules',
                onTap: () => LegalPolicySheet.show(context,
                    doc: LegalDocType.termsOfService)),
            _menuItem(context,
                icon: Icons.volunteer_activism_outlined,
                label: 'Cooperative Charter',
                subtitle: '5% Welfare allocation & worker dignity',
                onTap: () => LegalPolicySheet.show(context,
                    doc: LegalDocType.cooperativeCharter)),
            _menuItem(context,
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {}),
            _menuItem(context,
                icon: Icons.info_outline_rounded,
                label: 'About SahaKarya',
                subtitle: 'v1.0.0 — Cooperative Gig Services Platform',
                onTap: () => LegalPolicySheet.show(context,
                    doc: LegalDocType.cooperativeCharter)),

            const SizedBox(height: 14),
            AppButton(
              label: 'Logout',
              isOutlined: true,
              outlineColor: AppColors.danger,
              icon: Icons.logout_rounded,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    title: Text('Logout?',
                        style: GoogleFonts.sora(fontSize: 17)),
                    content: Text('Are you sure you want to logout?',
                        style: GoogleFonts.inter(fontSize: 13.5)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(authProvider.notifier).logout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        tileColor: AppColors.surface,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.inkSoft))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint, size: 22),
      ),
    )
        .animate(delay: Duration(milliseconds: 60))
        .fade(duration: 300.ms)
        .slideY(begin: 0.08, end: 0);
  }
}
