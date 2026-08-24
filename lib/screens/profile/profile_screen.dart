import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// User profile screen — settings, language toggle, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Profile',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(user?.name ?? 'U'),
                        style: GoogleFonts.sora(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'User',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? 'Phone',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.inkLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.history_rounded,
              label: 'Booking History',
              onTap: () => context.push('/history'),
            ),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              label: 'Saved Addresses',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.language_rounded,
              label: 'Language',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('English',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.teal,
                        fontWeight: FontWeight.w600)),
              ),
              onTap: () {
                // Language toggle would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language switch coming soon!')),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () {},
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline_rounded,
              label: 'About',
              subtitle: 'SahaKarya (सहकार्य) v1.0 — Cooperative Gig Platform',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              label: 'Logout',
              color: AppColors.error,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text('Are you sure you want to logout?'),
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    Widget? trailing,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        tileColor: AppColors.surface,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppColors.teal).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color ?? AppColors.teal, size: 22),
        ),
        title: Text(label,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.ink)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.inkLight))
            : null,
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                color: AppColors.inkMuted, size: 22),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}
