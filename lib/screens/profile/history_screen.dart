import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/service_category_tile.dart';

/// Booking history — list of past bookings with status pills.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bookingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Booking History',
            style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 56, color: AppColors.inkMuted),
                  const SizedBox(height: 16),
                  Text('No bookings yet',
                      style: GoogleFonts.sora(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Your completed bookings will appear here',
                      style: GoogleFonts.inter(color: AppColors.inkLight)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
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
                      child: Icon(
                        ServiceCategoryTile.getIconForService(
                            booking.serviceType),
                        color: AppColors.teal,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capitalizeFirst(booking.serviceType),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (booking.workerName != null)
                            Text(
                              booking.workerName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.inkLight,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(booking.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${booking.price.toStringAsFixed(0)}',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status.value)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(booking.status.value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'completed' || 'rated' => AppColors.success,
      'in_progress' => AppColors.orange,
      'requested' => AppColors.gold,
      'matched' => AppColors.teal,
      _ => AppColors.inkMuted,
    };
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
