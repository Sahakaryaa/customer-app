import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../services/booking_socket.dart';
import '../chat/chat_screen.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_tiles.dart';
import '../../widgets/avatar_badge.dart';

/// Live tracking — dark hero map (CARTO dark_all) with real Socket.IO
/// status/location updates, animated dash polyline driver→you, moving halo
/// marker, reconnecting banner and a slide-up status timeline panel.
class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  Booking? _booking;
  BookingStatus _status = BookingStatus.pending;
  final List<BookingStatus> _reachedStatuses = [];
  final Map<BookingStatus, DateTime?> _statusTimes = {};

  LatLng _customerLocation = LocationService.defaultLocation;
  LatLng _workerPos = LocationService.defaultLocation;
  bool _hasWorkerPos = false;
  double _workerBearing = 0;
  bool _connected = false;
  bool _cancelling = false;
  // Maps UX rule [Fundamental]: never fight an active pan. Once the user
  // drags the map themselves we stop auto-fitting the camera until they
  // explicitly tap re-center.
  bool _userPanned = false;

  // Smooth interpolation between successive location pings.
  late final AnimationController _moveCtrl;
  late final AnimationController _pulseCtrl;
  LatLng _from = LocationService.defaultLocation;
  LatLng _to = LocationService.defaultLocation;
  StreamSubscription<WorkerPing>? _pingSub;
  StreamSubscription<StatusUpdate>? _statusSub;
  StreamSubscription<bool>? _connSub;

  @override
  void initState() {
    super.initState();
    _customerLocation = ref.read(userLocationStateProvider).coordinates;
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
  }

  bool _reducedMotion = false;
  bool _motionChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_motionChecked) {
      _motionChecked = true;
      // Respect the OS "remove animations" accessibility setting: the
      // repeating halo pulse only runs when animations are allowed.
      _reducedMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!_reducedMotion) _pulseCtrl.repeat();
    }
  }

  Future<void> _startRealtime() async {
    final rt = ref.read(bookingSocketProvider);

    // Demo-mode convergence target: the customer's actual position, so the
    // simulated worker approaches THIS location instead of a hardcoded city.
    rt.setSimulationTarget(_customerLocation);

    // Seed from REST first.
    try {
      final booking =
          await ref.read(bookingDetailProvider(widget.bookingId).future);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _status = booking.status;
        if (booking.latitude != 0 || booking.longitude != 0) {
          _customerLocation = LatLng(booking.latitude, booking.longitude);
        }
        _seedTimeline(booking);
      });
      // Keep the sim target in sync once we know the booked address coords.
      rt.setSimulationTarget(_customerLocation);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, 'Could not refresh booking — retrying live',
          type: SnackType.warning);
    }

    rt.connect(widget.bookingId);

    _connSub = rt.connectionStream.listen((connected) {
      if (mounted) setState(() => _connected = connected);
    });

    _statusSub = rt.statusStream.listen((update) {
      if (update.newStatus != _status && mounted) {
        setState(() {
          _applyStatus(update.newStatus);
        });
      }
    });

    _pingSub = rt.locationStream.listen((ping) {
      if (ping.lat == 0 && ping.lng == 0) return;
      final target = LatLng(ping.lat, ping.lng);
      if (!_hasWorkerPos && mounted) {
        setState(() {
          _hasWorkerPos = true;
          _from = target;
          _to = target;
          _workerPos = target;
        });
        _fitCamera();
        return;
      }
      _animateTo(target);
    });
  }

  void _seedTimeline(Booking booking) {
    for (final s in BookingStatus.values) {
      if (s.stepIndex <= _status.stepIndex &&
          s != BookingStatus.declined &&
          s != BookingStatus.cancelled &&
          !_reachedStatuses.contains(s)) {
        _reachedStatuses.add(s);
        _statusTimes[s] = null; // historical times unknown
      }
    }
    _reachedStatuses.sort((a, b) => a.stepIndex.compareTo(b.stepIndex));
  }

  void _applyStatus(BookingStatus newStatus) {
    _statusTimes[newStatus] = DateTime.now();
    if (!_reachedStatuses.contains(newStatus)) {
      _reachedStatuses.add(newStatus);
      _reachedStatuses.sort((a, b) => a.stepIndex.compareTo(b.stepIndex));
    }
    _status = newStatus;
  }

  void _animateTo(LatLng target) {
    setState(() {
      // Resume from where the marker is CURRENTLY rendered — if the previous
      // leg was interrupted mid-flight, starting from the raw old fix would
      // visibly yank the marker backwards on every new ping.
      final renderedNow = interpolateAlong(
        [_from, _to],
        Curves.easeInOut.transform(_moveCtrl.value),
      );
      _from = _moveCtrl.isAnimating ? renderedNow : _workerPos;
      _to = target;
      // Commit the logical position to the newest fix. Without this, the
      // polyline, ETA distance, bearing and camera framing all keep reading
      // the stale first fix while the marker loops back to it.
      _workerPos = target;
      _workerBearing = bearingDegrees(
          _from.latitude, _from.longitude,
          target.latitude, target.longitude);
    });
    _moveCtrl.forward(from: 0).whenComplete(() => _keepBothPinsVisible());
  }

  /// While following (the user hasn't panned), gently re-frame only when a
  /// pin fully leaves the viewport — never mid-gesture, never fighting pans.
  void _keepBothPinsVisible() {
    if (_userPanned || !_hasWorkerPos) return;
    try {
      final bounds = _mapController.camera.visibleBounds;
      if (!bounds.contains(_workerPos) ||
          !bounds.contains(_customerLocation)) {
        _fitCamera();
      }
    } catch (_) {// Camera not ready yet — ignore.
    }
  }

  void _fitCamera() {
    // Purpose-built camera fit: frames BOTH pins with screen-edge padding
    // (extra top padding keeps pins clear of the back/status overlay).
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [_customerLocation, _workerPos],
        padding: const EdgeInsets.fromLTRB(56, 140, 56, 64),
      ),
    );
  }

  int get _etaMinutes {
    if (!_hasWorkerPos || _status != BookingStatus.enRoute) return 0;
    final km = haversineKm(_customerLocation.latitude,
        _customerLocation.longitude, _workerPos.latitude, _workerPos.longitude);
    return math.max(1, (km / 18 * 60).ceil()); // ~18 km/h city average
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancel this booking?',
            style: GoogleFonts.sora(fontSize: 17)),
        content: Text(
          'Your service partner will be notified immediately.',
          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateBookingStatus(
          bookingId: widget.bookingId, status: 'cancelled');
      if (mounted) {
        AppSnackBar.show(context, 'Booking cancelled', type: SnackType.info);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancelling = false);
        AppSnackBar.show(context, ApiClient.friendlyError(e),
            type: SnackType.error);
      }
    }
  }

  @override
  void dispose() {
    _pingSub?.cancel();
    _statusSub?.cancel();
    _connSub?.cancel();
    _moveCtrl.dispose();
    _pulseCtrl.dispose();
    ref.read(bookingSocketProvider).disconnect(); // stop socket + polling
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── Full-bleed map hero ──
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.40,
            child: AnimatedBuilder(
              animation: _moveCtrl,
              builder: (context, _) => FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _hasWorkerPos
                    ? _workerPos
                    : _customerLocation,
                initialZoom: 14.2,
                minZoom: 11,
                maxZoom: 18,
                onMapEvent: (event) {
                  // Distinguish genuine user pans from programmatic camera
                  // moves so follow-mode never fights the user's hand.
                  if (event is MapEventMoveStart && !_userPanned) {
                    setState(() => _userPanned = true);
                  }
                },
              ),
              children: [
                AppTiles.voyager(),
                PolylineLayer(
                  polylines: [
                    // Casing — white halo keeps the route readable on the
                    // light Voyager basemap.
                    Polyline(
                      points: [_workerPos, _customerLocation],
                      strokeWidth: 7,
                      color: Colors.white.withValues(alpha: 0.9),
                      strokeCap: StrokeCap.round,
                    ),
                    // Animated dashed route driver→you
                    Polyline(
                      points: [_workerPos, _customerLocation],
                      strokeWidth: 4.5,
                      color: AppColors.primaryDeep,
                      strokeCap: StrokeCap.round,
                      pattern: StrokePattern.dashed(
                        segments: const [12, 9],
                      ),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Customer pin (gold per spec)
                    Marker(
                      point: _customerLocation,
                      width: 46,
                      height: 46,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.warning,
                          border: Border.all(
                              color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning
                                  .withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    // Moving worker halo marker
                    if (_hasWorkerPos)
                      Marker(
                        point: interpolateAlong(
                          [_from, _to],
                          Curves.easeInOut.transform(_moveCtrl.value),
                        ),
                        width: 64,
                        height: 64,
                        child: AnimatedBuilder(
                          animation:
                              Listenable.merge([_moveCtrl, _pulseCtrl]),
                          builder: (context, _) {
                            final pulse = _reducedMotion ? 0.0 : _pulseCtrl.value;
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Transform.rotate(
                                  angle: _workerBearing * math.pi / 180,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration:
                                        const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient:
                                          AppColors.primaryGradient,
                                    ),
                                    child: Container(
                                      margin:
                                          const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 2),
                                      ),
                                      child: const Icon(
                                          Icons.navigation_rounded,
                                          size: 17,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                // Pulsing halo ring (repeating)
                                Container(
                                  width:
                                      38 + (26 * pulse),
                                  height:
                                      38 + (26 * pulse),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryLight
                                          .withValues(alpha:
                                              (1 - pulse) *
                                                  0.55),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
                AppTiles.attribution(),
              ],
            ),
            ),
          ),

          // ── Top overlay: back + reconnecting banner + status chip ──
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _circleBtn(Icons.arrow_back_rounded, () {
                        context.canPop()
                            ? context.pop()
                            : context.go('/home');
                      }),
                      const Spacer(),
                      StatusPill(status: _status),
                    ],
                  ).animate().fade(duration: 300.ms),
                  if (!_connected)
                    Builder(builder: (context) {
                      final banner = Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reconnecting to live updates…',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      );
                      // Attention pulse is decorative — static under the OS
                      // remove-animations accessibility setting.
                      if (_reducedMotion) return banner;
                      return banner
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(begin: 1, end: 0.55, duration: 900.ms);
                    }),
                ],
              ),
            ),
          ),

          // ── Recenter control (fits both pins; thumb-zone placement) ──
          Align(
            alignment: const Alignment(1.0, -0.30),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _circleBtn(Icons.my_location_rounded, () {
                setState(() => _userPanned = false); // resume follow
                _fitCamera();
              }),
            ),
          ).animate().fade(duration: 300.ms),

          // ── Slide-up panel ──
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.32,
            maxChildSize: 0.62,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      _buildHeaderRow(),
                      const SizedBox(height: 14),

                      // ETA card
                      if (_status == BookingStatus.enRoute ||
                          _status == BookingStatus.accepted)
                        _etaCard(),
                      if (_status == BookingStatus.completed ||
                          _status == BookingStatus.started)
                        _completedCard(),

                      const SizedBox(height: 14),

                      // Contact row
                      if (_booking?.workerName != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Call',
                                isOutlined: true,
                                icon: Icons.phone_in_talk_rounded,
                                height: 46,
                                onPressed: () => AppSnackBar.show(context,
                                    'Connecting to ${_booking!.workerName}…',
                                    type: SnackType.info),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AppButton(
                                label: 'Chat',
                                isOutlined: true,
                                outlineColor: AppColors.info,
                                icon: Icons.chat_bubble_rounded,
                                height: 46,
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      bookingId: widget.bookingId,
                                      peerName: _booking!.workerName ?? 'Partner',
                                      senderRole: 'customer',
                                      transport: SocketChatTransport(
                                        bookingId: widget.bookingId,
                                        myRole: 'customer',
                                        chatStream:
                                            ref.read(bookingSocketProvider).chatStream,
                                        sendFn: (text) => ref
                                            .read(bookingSocketProvider)
                                            .sendChatMessage(text,
                                                senderRole: 'customer'),
                                      ),
                                    ),
                                  ));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_booking?.cancellable ?? false) ...[
                        GestureDetector(
                          onTap: _cancelling ? null : _cancelBooking,
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: _cancelling
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text('Cancel booking',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.danger)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      Text('Status Timeline',
                          style: GoogleFonts.sora(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _timeline(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 44px minimum tap target (a11y rule).
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.94),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final workerName = _booking?.workerName ?? 'Awaiting assignment';
    final price = _booking?.price ?? 0;
    final address = _booking?.address ?? '';

    return Row(
      children: [
        AvatarBadge(name: workerName, size: 46, online: _connected),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(workerName,
                  style: GoogleFonts.sora(
                      fontSize: 15.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                address.isEmpty
                    ? '₹${price.toStringAsFixed(0)} • Live GPS connected'
                    : '$address • ₹${price.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    fontSize: 11.5, color: AppColors.inkSoft),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (_connected)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.success),
                ),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.success)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _etaCard() {
    final waiting = _etaMinutes == 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primaryLight.withValues(alpha: 0.12),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            waiting ? Icons.schedule_rounded : Icons.electric_moped_rounded,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              waiting
                  ? 'Partner confirmed — heading your way soon'
                  : 'Arriving in ~$_etaMinutes min '
                      '(${haversineKm(_customerLocation.latitude, _customerLocation.longitude, _workerPos.latitude, _workerPos.longitude).toStringAsFixed(1)} km away)',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 150.ms).fade(duration: 320.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _completedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.success.withValues(alpha: 0.08),
          AppColors.success.withValues(alpha: 0.05),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _status == BookingStatus.completed
                  ? 'Service completed — settle invoice'
                  : 'Service in progress at your location.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          if (_status == BookingStatus.completed)
            GestureDetector(
              onTap: () => context.go('/booking/${widget.bookingId}/payment'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.amberGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text('Pay Bill',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
            ),
        ],
      ),
    ).animate(delay: 150.ms).fade(duration: 320.ms).slideY(begin: 0.15, end: 0);
  }

  Widget _timeline() {
    const steps = [
      (BookingStatus.accepted, Icons.handshake_rounded, 'Accepted'),
      (BookingStatus.enRoute, Icons.electric_moped_rounded, 'En Route'),
      (BookingStatus.arrived, Icons.location_on_rounded, 'Arrived'),
      (BookingStatus.started, Icons.handyman_rounded, 'Started'),
      (BookingStatus.completed, Icons.check_circle_rounded, 'Completed'),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final (status, icon, label) = steps[i];
        final reached = _reachedStatuses.any(
            (s) => s == status || s.stepIndex > status.stepIndex && s != BookingStatus.cancelled);
        final active = _status == status;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    width: active ? 34 : 28,
                    height: active ? 34 : 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: reached || active
                          ? AppColors.primaryGradient
                          : null,
                      color: reached || active ? null : AppColors.surfaceAlt,
                      border: Border.all(
                        color: reached || active
                            ? Colors.transparent
                            : AppColors.border,
                        width: 1.6,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(icon,
                        size: active ? 17 : 14,
                        color: reached || active
                            ? Colors.white
                            : AppColors.inkFaint),
                  ),
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 2.4,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: reached && !active
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: active ? 8 : 6, bottom: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: reached || active
                                ? AppColors.ink
                                : AppColors.inkFaint,
                          ),
                          child: Text(label),
                        ),
                      ),
                      if (_statusTimes[status] != null)
                        Text(
                          '${_statusTimes[status]!.hour}:${_statusTimes[status]!.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: AppColors.inkFaint),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Small status pill shown over the map.
class StatusPill extends StatelessWidget {
  final BookingStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
