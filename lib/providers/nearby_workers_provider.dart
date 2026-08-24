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

/// Nearby workers provider — fetches workers based on location, service type, and search query.
final nearbyWorkersProvider =
    FutureProvider.family<List<Worker>, LatLng>((ref, location) async {
  final serviceType = ref.watch(selectedServiceProvider);
  final searchQuery =
      ref.watch(workerSearchQueryProvider)?.trim().toLowerCase();

  List<Worker> workers;
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 350));
    workers = MockDataService.getMockWorkers(serviceType: serviceType);
  } else {
    final api = ref.read(apiClientProvider);
    workers = await api.getNearbyWorkers(
      lat: location.latitude,
      lng: location.longitude,
      serviceType: serviceType,
    );
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

  return workers;
});

/// Single worker profile provider.
final workerProfileProvider =
    FutureProvider.family<Worker, String>((ref, workerId) async {
  if (useMockData) {
    await Future.delayed(const Duration(milliseconds: 400));
    final workers = MockDataService.getMockWorkers();
    return workers.firstWhere(
      (w) => w.id == workerId,
      orElse: () => workers.first,
    );
  }

  final api = ref.read(apiClientProvider);
  return api.getWorkerProfile(workerId);
});
