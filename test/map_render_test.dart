import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:customer_app/models/location_data.dart';
import 'package:customer_app/models/worker.dart';
import 'package:customer_app/providers/nearby_workers_provider.dart';
import 'package:customer_app/screens/worker_discovery/worker_list_screen.dart';
import 'package:customer_app/services/location_service.dart';
import 'package:customer_app/theme/app_theme.dart';

/// Real map-render verification: pumps the actual WorkerListScreen in MAP
/// mode and asserts the FlutterMap + markers exist, then simulates a marker
/// tap (selection) — proving the discovery map works end-to-end.
Worker _worker(String id, String name,
        {double lat = 16.9368, double lng = 82.2375, bool online = true}) =>
    Worker(
      id: id,
      userId: 'u-$id',
      name: name,
      skills: const ['electrician'],
      certificationStatus: 'verified',
      latitude: lat,
      longitude: lng,
      ratingAvg: 4.6,
      totalRatings: 42,
      isOnline: online,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Discovery map renders FlutterMap with worker + user markers',
      (tester) async {
    final workers = [
      _worker('w1', 'Ramesh Kumar'),
      _worker('w2', 'Suresh Rao', lat: 16.9400, lng: 82.2400),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Deterministic location for the map center.
          userLocationStateProvider.overrideWith((ref) => UserLocationNotifier()
            ..setLocation(const CooperativeLocation(
              id: 'test',
              areaName: 'Test Area',
              subDistrict: 'Test',
              city: 'Test City',
              coordinates: LatLng(16.9368, 82.2375),
              activeWorkers: 2,
              federationHub: 'Test Hub',
            ))),
          nearbyWorkersProvider.overrideWith(
            (ref, _) async => workers,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkerListScreen(serviceType: 'electrician'),
        ),
      ),
    );
    await tester.pump(); // first build
    await tester.pumpAndSettle();

    // Switch to MAP view via the visible toggle button.
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    // The real FlutterMap widget must be on stage…
    expect(find.byType(FlutterMap), findsOneWidget);
    // …with a MarkerLayer holding BOTH pins (user + 2 workers).
    final markerLayers = tester.widgetList<MarkerLayer>(
      find.byType(MarkerLayer),
    );
    var markerCount = 0;
    for (final layer in markerLayers) {
      markerCount += layer.markers.length;
    }
    expect(markerCount, 3, reason: 'user pin + 2 worker pins expected');
  });

  testWidgets('Marker tap selects worker and shows peek card', (tester) async {
    final workers = [_worker('w1', 'Ramesh Kumar')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userLocationStateProvider.overrideWith((ref) => UserLocationNotifier()
            ..setLocation(const CooperativeLocation(
              id: 'test',
              areaName: 'Test Area',
              subDistrict: 'Test',
              city: 'Test City',
              coordinates: LatLng(16.9368, 82.2375),
              activeWorkers: 1,
              federationHub: 'Test Hub',
            ))),
          nearbyWorkersProvider.overrideWith((ref, _) async => workers),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkerListScreen(serviceType: 'electrician'),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    // Tap the marker's inner hit area (GestureDetector inside the marker).
    final gestureDetectors = find.descendant(
      of: find.byType(MarkerLayer),
      matching: find.byType(GestureDetector),
    );
    expect(gestureDetectors, findsWidgets);
    await tester.tap(gestureDetectors.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Selection peek card appears with the worker's name.
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('View Profile'), findsOneWidget);
  });
}
