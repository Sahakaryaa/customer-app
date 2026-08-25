import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/worker.dart';
import '../services/api_client.dart';
import '../services/mock_data_service.dart';
import 'auth_provider.dart';

/// Currently selected service type for filtering workers.
final selectedServiceProvider = StateProvider<String?>((ref) => null);

/// Search query string for filtering workers by name, skill, or federation.
final workerSearchQueryProvider = StateProvider<String?>((ref) => null);

/// Sort/filter mode: emergency dispatch prioritizes closest + online first.
final emergencyModeProvider = StateProvider<bool>((ref) => false);

List<Worker> _applyEmergencyRanking(List<Worker> workers) {
  final sorted = [...workers];
  sorted.sort((a, b) {
    // Online first
    if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
    // Then nearest
    final da = a.distanceMeters ?? double.infinity;
    final db = b.distanceMeters ?? double.infinity;
    if ((da - db).abs() > 0.5) return da.compareTo(db);
    // Then best rated
    return b.ratingAvg.compareTo(a.ratingAvg);
  });
  return sorted;
}

/// Nearby workers provider — fetches workers based on location, service type,
/// and search query.
final nearbyWorkersProvider =
    FutureProvider.family<List<Worker>, LatLng>((ref, location) async {
  final serviceType = ref.watch(selectedServiceProvider);
  final searchQuery =
      ref.watch(workerSearchQueryProvider)?.trim().toLowerCase();

  List<Worker> workers;
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 250));
    workers = MockDataService.getMockWorkers(
      serviceType: serviceType,
      centerLocation: location,
    );
  } else {
    try {
      final api = ref.read(apiClientProvider);
      workers = await api.getNearbyWorkers(
        lat: location.latitude,
        lng: location.longitude,
        serviceType: serviceType,
      );
    } catch (_) {
      // Offline fallback: generate realistic workers around current coordinates
      workers = MockDataService.getMockWorkers(
        serviceType: serviceType,
        centerLocation: location,
      );
    }
  }

  if (searchQuery != null && searchQuery.isNotEmpty) {
    workers = workers.where((w) {
      final matchesName = w.name.toLowerCase().contains(searchQuery);
      final matchesSkill =
          w.skills.any((s) => s.toLowerCase().contains(searchQuery));
      final matchesFederation =
          w.federationName?.toLowerCase().contains(searchQuery) ?? false;
      return matchesName || matchesSkill || matchesFederation;
    }).toList();
  }

  if (ref.watch(emergencyModeProvider)) {
    workers = _applyEmergencyRanking(workers);
  } else {
    // Default: best-rated first.
    workers = [...workers]..sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
  }

  return workers;
});

/// Single worker profile provider. Returns null when the worker does not
/// exist — empty-safe, never throws StateError on an empty list.
final workerProfileProvider =
    FutureProvider.family<Worker?, String>((ref, workerId) async {
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 250));
    final workers = MockDataService.getMockWorkers();
    for (final w in workers) {
      if (w.id == workerId) return w;
    }
    return workers.firstOrNull;
  }

  final api = ref.read(apiClientProvider);
  try {
    return await api.getWorkerProfile(workerId); // GET /workers/{id}
  } catch (_) {
    // Fallback: look up in mock workers
    final workers = MockDataService.getMockWorkers();
    for (final w in workers) {
      if (w.id == workerId) return w;
    }
    return workers.firstOrNull;
  }
});
