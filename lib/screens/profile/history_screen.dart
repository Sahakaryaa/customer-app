import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/status_chip.dart';

/// Booking history — grouped by date with StatusChips; tap routes to
/// tracking / rating depending on state. Designed EmptyState when none.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(bookingHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Booking History',
            style: GoogleFonts.sora(fontWeight: FontWeight.w700)),
      ),
      body: historyAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonBox(height: 84, borderRadius: 20),
            const SizedBox(height: 10),
            SkeletonBox(height: 84, borderRadius: 20),
            const SizedBox(height: 10),
            SkeletonBox(height: 84, borderRadius: 20),
          ],
        ),
        error: (err, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load history',
          subtitle:
              'We had trouble reaching your bookings. Check your connection and retry.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(bookingHistoryProvider),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No bookings yet',
              subtitle:
                  'Book your first cooperative service and it will show up here.',
              actionLabel: 'Find a worker',
              onAction: () => context.go('/workers'),
            );
          }

          final groups = _groupByDate(bookings);

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            onRefresh: () async => ref.invalidate(bookingHistoryProvider),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _flatCount(groups),
              itemBuilder: (context, index) =>
                  _buildFlatItem(context, ref, groups, index)
                      .animate(delay: Duration(milliseconds: 50 * index.clamp(0, 14)))
                      .fade(duration: 300.ms)
                      .slideY(begin: 0.12, end: 0),
            ),
          );
        },
      ),
    );
  }

  // ── Grouping helpers ──

  List<MapEntry<String, List<Booking>>> _groupByDate(List<Booking> bookings) {
    final map = <String, List<Booking>>{};
    for (final b in bookings) {
      map.putIfAbsent(_dateLabel(b.createdAt), () => []).add(b);
    }
    return map.entries.toList();
  }

  int _flatCount(List<MapEntry<String, List<Booking>>> groups) {
    var n = 0;
    for (final g in groups) {
      n += 1 + g.value.length;
    }
    return n;
  }

  Widget _buildFlatItem(BuildContext context, WidgetRef ref,
      List<MapEntry<String, List<Booking>>> groups, int index) {
    var cursor = index;
    for (final g in groups) {
      if (cursor == 0) return _dateHeader(g.key);
      cursor -= 1;
      if (cursor < g.value.length) {
        final booking = g.value[cursor];
        return _BookingTile(
          booking: booking,
          onTap: () => _openBooking(context, booking),
        );
      }
      cursor -= g.value.length;
    }
    return const SizedBox.shrink();
  }

  void _openBooking(BuildContext context, Booking booking) {
    if (booking.rateable) {
      context.push('/booking/${booking.id}/rate');
      return;
    }
    if (booking.isActive || booking.status == BookingStatus.completed) {
      context.push('/booking/${booking.id}/tracking');
      return;
    }
    AppSnackBar.show(
      context,
      switch (booking.status) {
        BookingStatus.declined => 'This booking was declined by the partner.',
        BookingStatus.cancelled => 'This booking was cancelled.',
        _ => 'Booking ${booking.status.label.toLowerCase()}.',
      },
      type: SnackType.info,
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(that).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _dateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.sora(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.11),
                  AppColors.primaryLight.withValues(alpha: 0.16),
                ]),
              ),
              child: Icon(
                switch (booking.serviceType) {
                  'electrician' => Icons.bolt_rounded,
                  'plumber' => Icons.plumbing_rounded,
                  'carpenter' => Icons.carpenter_rounded,
                  'painter' => Icons.format_paint_rounded,
                  'cleaner' => Icons.cleaning_services_rounded,
                  'caregiver' => Icons.health_and_safety_rounded,
                  'driver' => Icons.directions_car_rounded,
                  'gardener' => Icons.yard_rounded,
                  _ => Icons.handyman_rounded,
                },
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.workerName ??
                        booking.serviceType[0].toUpperCase() +
                            booking.serviceType.substring(1),
                    style: GoogleFonts.sora(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.address?.isNotEmpty == true
                        ? booking.address!
                        : '${booking.createdAt.day}/${booking.createdAt.month} · '
                            '#${booking.id.length > 6 ? booking.id.substring(0, 6) : booking.id}',
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: AppColors.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 5),
                StatusChip(status: booking.status, dense: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
