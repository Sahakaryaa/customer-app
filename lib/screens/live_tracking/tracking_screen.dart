import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../../widgets/status_stepper.dart';
import '../../widgets/primary_button.dart';
import '../../models/booking.dart';
import '../../services/location_service.dart';
import '../../widgets/cooperative_badge.dart';
import '../../widgets/glass_card.dart';

/// Professional 60 FPS live tracking screen with continuous coordinate interpolation,
/// rotating vehicle heading, animated radar beacon pulses, and real-time telemetry card.
class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with TickerProviderStateMixin {
  late LatLng _customerLocation;
  late List<LatLng> _routePoints;
  BookingStatus _currentStatus = BookingStatus.requested;
  final MapController _mapController = MapController();

  // Animation controllers
  late AnimationController _moveController;
  late Animation<double> _moveAnimation;
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  // Real-time telemetry values
  LatLng _currentWorkerPos = LocationService.defaultLocation;
  double _workerBearing = 0.0; // in degrees
  double _remainingDistanceKm = 1.8;
  int _etaMinutes = 6;
  bool _hasArrived = false;

  @override
  void initState() {
    super.initState();
    final activeLoc = ref.read(userLocationStateProvider);
    _customerLocation = activeLoc.coordinates;

    // Generate a high-resolution 12-waypoint curved realistic road approach path
    _generateRoadRoute(_customerLocation);

    // Initialize continuous motion controller (16 seconds total ride simulation)
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutCubic,
    );

    // Radar pulse controller (repeating 1.6s loop)
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOut,
    );

    // Listen to continuous motion ticks (60fps continuous glide)
    _moveAnimation.addListener(_onMotionTick);
    _moveAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onWorkerArrived();
      }
    });

    // Start simulation with staged status transitions
    _startStagedTimeline();
  }

  void _generateRoadRoute(LatLng dest) {
    // Generate curved road waypoints approaching destination from 1.8km North-East
    _routePoints = [
      LatLng(dest.latitude + 0.0145, dest.longitude + 0.0120),
      LatLng(dest.latitude + 0.0128, dest.longitude + 0.0098),
      LatLng(dest.latitude + 0.0105, dest.longitude + 0.0084),
      LatLng(dest.latitude + 0.0082, dest.longitude + 0.0068),
      LatLng(dest.latitude + 0.0064, dest.longitude + 0.0051),
      LatLng(dest.latitude + 0.0048, dest.longitude + 0.0039),
      LatLng(dest.latitude + 0.0032, dest.longitude + 0.0024),
      LatLng(dest.latitude + 0.0018, dest.longitude + 0.0012),
      LatLng(dest.latitude + 0.0006, dest.longitude + 0.0004),
      dest,
    ];
    _currentWorkerPos = _routePoints.first;
    _workerBearing = _calculateBearing(_routePoints[0], _routePoints[1]);
  }

  void _startStagedTimeline() {
    // 0s: Requested
    // 1.5s: Matched & Federation Partner Assigned
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _currentStatus = BookingStatus.matched);
        _moveController.forward();
      }
    });
  }

  void _onMotionTick() {
    if (!mounted || _routePoints.isEmpty) return;

    final progress = _moveAnimation.value; // 0.0 to 1.0
    final totalSegments = _routePoints.length - 1;
    final scaledProgress = progress * totalSegments;
    final segmentIndex = scaledProgress.floor().clamp(0, totalSegments - 1);
    final segmentFraction = scaledProgress - segmentIndex;

    final startPoint = _routePoints[segmentIndex];
    final endPoint = _routePoints[segmentIndex + 1];

    // Smooth linear interpolation along the active road segment
    final interpolatedLat =
        startPoint.latitude + (endPoint.latitude - startPoint.latitude) * segmentFraction;
    final interpolatedLng =
        startPoint.longitude + (endPoint.longitude - startPoint.longitude) * segmentFraction;

    final newPos = LatLng(interpolatedLat, interpolatedLng);
    final bearing = _calculateBearing(startPoint, endPoint);

    setState(() {
      _currentWorkerPos = newPos;
      _workerBearing = bearing;
      _remainingDistanceKm = ((1.0 - progress) * 1.8).clamp(0.05, 1.8);
      _etaMinutes = ((1.0 - progress) * 6).ceil().clamp(1, 6);
    });

    // Gently pan camera with the moving worker every 15 frames
    if ((progress * 100).toInt() % 8 == 0) {
      _mapController.move(newPos, 15.2);
    }
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lon1 = from.longitudeInRad;
    final lat2 = to.latitudeInRad;
    final lon2 = to.longitudeInRad;

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final radians = math.atan2(y, x);
    return (radians * 180 / math.pi + 360) % 360;
  }

  void _onWorkerArrived() {
    if (!mounted) return;
    setState(() {
      _hasArrived = true;
      _remainingDistanceKm = 0.0;
      _etaMinutes = 0;
      _currentStatus = BookingStatus.inProgress;
    });

    // 4s later → service completed
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _currentStatus = BookingStatus.completed);
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Service Tracking',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Booking #${widget.bookingId.substring(0, math.min(8, widget.bookingId.length))}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center Map',
            onPressed: () => _mapController.move(_currentWorkerPos, 15.4),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: StatusStepper(currentStatus: _currentStatus),
          ),

          // Live Interactive Map Viewport
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _customerLocation,
                    initialZoom: 14.8,
                    minZoom: 11.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // Real Google Maps Roadmap Tile Layer
                    TileLayer(
                      urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                      userAgentPackageName: 'com.sahakarya.customer_app',
                      maxZoom: 20,
                    ),

                    // Approach Route Polyline (Google Maps double stroke style)
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF0F4C5C).withValues(alpha: 0.9),
                            strokeWidth: 6.0,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                          Polyline(
                            points: _routePoints,
                            color: const Color(0xFF14B8A6),
                            strokeWidth: 4.0,
                            strokeCap: StrokeCap.round,
                            strokeJoin: StrokeJoin.round,
                          ),
                        ],
                      ),

                    // Animated Markers Layer
                    MarkerLayer(
                      markers: [
                        // 1. Customer Destination Marker with Teal Radar Wave
                        Marker(
                          point: _customerLocation,
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _radarAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Expanding outer pulse ring
                                  Container(
                                    width: 32 + (40 * _radarAnimation.value),
                                    height: 32 + (40 * _radarAnimation.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.teal.withValues(
                                        alpha: (1.0 - _radarAnimation.value) * 0.35,
                                      ),
                                      border: Border.all(
                                        color: AppColors.teal.withValues(
                                          alpha: (1.0 - _radarAnimation.value) * 0.6,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Pin icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.teal,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.teal.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.home_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // 2. Smoothly Moving Worker Marker with Orange Radar Beacon & Heading
                        Marker(
                          point: _currentWorkerPos,
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _radarAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Expanding orange beacon ring
                                  Container(
                                    width: 34 + (38 * _radarAnimation.value),
                                    height: 34 + (38 * _radarAnimation.value),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.orange.withValues(
                                        alpha: (1.0 - _radarAnimation.value) * 0.4,
                                      ),
                                    ),
                                  ),
                                  // Rotatable vehicle marker
                                  Transform.rotate(
                                    angle: (_workerBearing * math.pi / 180),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: AppColors.orangeGradient,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.orange.withValues(alpha: 0.5),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.white, width: 2.5),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.navigation_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
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
                  ],
                ),

                // Floating Live Telemetry GlassCard (ETA + Distance Progress)
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _hasArrived
                                ? AppColors.teal.withValues(alpha: 0.12)
                                : AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _hasArrived ? Icons.verified_rounded : Icons.electric_moped_rounded,
                            color: _hasArrived ? AppColors.teal : AppColors.orange,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hasArrived
                                    ? 'Partner Arrived at Location'
                                    : 'Arriving in ~$_etaMinutes mins',
                                style: GoogleFonts.sora(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hasArrived
                                    ? 'Service commencing • Delhi Central Federation'
                                    : '${_remainingDistanceKm.toStringAsFixed(1)} km away • Live GPS Connected',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Worker Details & Actions Card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Worker Profile Header
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.teal.withValues(alpha: 0.12),
                          child: Text(
                            'RK',
                            style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.verified_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Ramesh Kumar',
                                style: GoogleFonts.sora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const CooperativeBadge(
                                federationName: 'SahaKarya Certified',
                                isCompact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Master Electrician • 840+ Completed Jobs',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.inkLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Action CTA
                if (_currentStatus == BookingStatus.completed)
                  PrimaryButton(
                    label: 'Proceed to Payment (₹450)',
                    icon: Icons.payment_rounded,
                    onPressed: () => context.go('/booking/${widget.bookingId}/payment'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Call Partner',
                          icon: Icons.phone_in_talk_rounded,
                          isOutlined: true,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Connecting to Ramesh Kumar (+91 98111 00001)...'),
                                backgroundColor: AppColors.teal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'SOS Emergency',
                          icon: Icons.shield_rounded,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SahaKarya Federation 24/7 Safety Desk Alerted!'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
