# SahaKarya Customer App — Development Log & Change Record

This document tracks all changes, additions, modifications, and removals performed on the **SahaKarya Customer App** (`customer_app`) across each development run for full traceability and future reference.

---

## 📅 Run History & Iteration Logs

### [Run 5] — 2026-08-24: Real Google Maps Roadmap Layer Integration

#### 🎯 Objectives
Upgrade map rendering across discovery and tracking screens to real Google Maps roadmap tiles with double-stroke polyline routing.

#### ✏️ Modified
- **`lib/screens/live_tracking/tracking_screen.dart`**:
  - Replaced Carto tiles with real Google Maps Roadmap tile server (`https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}` with subdomains `['mt0', 'mt1', 'mt2', 'mt3']`).
  - Added double-stroke Google Maps styled navigation polyline (dark border with cyan route).
- **`lib/screens/worker_discovery/worker_list_screen.dart`**:
  - Upgraded discovery map view to Google Maps roadmap tile layer.

#### 🔍 Verification & Lint Status
- `dart analyze`: **0 errors, 0 warnings, 0 issues**.

---

### [Run 4] — 2026-08-24: Fix /book Route Resolution & BookingFlow Parameters

#### 🎯 Objectives
Resolve `GoException: no routes for location: /book?...` by registering `/book` path and parameter bindings.

#### ➕ Added
- Registered `/book` route in `lib/router.dart` supporting `worker`, `workerId`, `service`, and `workerName` query parameters.

#### ✏️ Modified
- **`lib/router.dart`**: Handled both `/book` and `/booking/new` aliases uniformly.
- **`lib/screens/booking_flow/booking_flow_screen.dart`**: Added constructor and `initState` support for `service` and `workerName` parameters passed from the worker profile screen.

#### 🔍 Verification & Lint Status
- `dart analyze`: **0 errors, 0 warnings, 0 issues**.

---

### [Run 3] — 2026-08-24: Immersive UI/UX Refinements (Design Skill v2.0)

#### 🎯 Objectives
Apply comprehensive UI/UX guidelines from `08-flutter-immersive-ui-skill.md` including Bento grid layouts, Glassmorphism 2.0, Hero spatial transitions, haptic feedback, and fix CI compilation compatibility.

#### ➕ Added
- **`lib/widgets/glass_card.dart`**: Glassmorphism 2.0 component with static `BackdropFilter` (`sigmaX: 16, sigmaY: 16`), high-contrast semi-transparent borders, and accessibility considerations.
- **`flutter_animate: ^4.5.2`** in `pubspec.yaml` for smooth 60 FPS entrance transitions.
- **`MockDataService.getMockReviews()`** in `lib/services/mock_data_service.dart` providing rich mock feedback for worker dossiers.

#### ✏️ Modified
- **`lib/screens/home/home_screen.dart`**:
  - Re-architected home layout into a **Bento Grid**:
    - *Hero Cell*: Emergency Fast-Track Dispatch banner with live breathing pulse and `HapticFeedback.mediumImpact()`.
    - *Medium Supporting Cells*: 2-column bento widgets for "15+ Verified Workers" and "5% Social Security Welfare Fund".
    - *Category Tiles*: Staggered micro-animated trade chips.
- **`lib/widgets/worker_card.dart`**:
  - Wrapped avatar in `Hero(tag: 'worker-avatar-${widget.worker.id}')` for continuous spatial navigation.
  - Added `HapticFeedback.lightImpact()` on tap.
  - Fixed availability status to check `worker.isOnline`.
- **`lib/screens/worker_discovery/worker_profile_screen.dart`**:
  - Added matching `Hero(tag: 'worker-avatar-${worker.id}')` avatar container.
  - Implemented `GlassCard` overlay for rating & job statistics.
  - Handled nullable `worker.federationName` fallback safely.
- **`lib/widgets/cooperative_badge.dart`**:
  - Integrated `flutter_animate` elastic pop with shimmering gold accent.
- **`lib/screens/live_tracking/tracking_screen.dart`**:
  - Wrapped floating telemetry ETA chip over OpenStreetMap in `GlassCard`.
- **`pubspec.yaml`**:
  - Relaxed SDK constraint to `sdk: '>=3.3.0 <4.0.0'` for CI/CD compatibility.
  - Re-added `device_preview: ^1.2.0`.

#### ❌ Removed / Cleaned Up
- Removed duplicate parameter names `(_, __)` in `worker_profile_screen.dart`.
- Removed experimental null-aware map elements (`?param`) in `lib/services/api_client.dart` in favor of standard Dart map conditionals.
- Removed deprecated `useInheritedMediaQuery` in `lib/main.dart`.

#### 🔍 Verification & Lint Status
- `dart analyze`: **0 errors, 0 warnings, 0 issues**.
- Build status: Release APK pipeline active via `.github/workflows/release.yml`.

---

### [Run 2] — 2026-08-24: CI/CD Release Pipeline & API Client Standardization

#### 🎯 Objectives
Automate build artifacts and GitHub Releases on push/tags and standardize network layers.

#### ➕ Added
- **`.github/workflows/release.yml`**: GitHub Actions workflow to automatically build release APK and AAB, upload artifacts, and create versioned GitHub Releases.

#### ✏️ Modified
- **`lib/services/api_client.dart`**: Fixed Dio map element syntax to support both local SDK 3.13 and cloud Dart 3.7.

---

### [Run 1] — Initial Project Setup & Architecture

#### 🎯 Objectives
Bootstrap the Flutter Customer mobile application for the SahaKarya Cooperative Gig Services Platform.

#### ➕ Added
- **Core Architecture**: Riverpod state management, GoRouter declarative routing, FlutterMap with OpenStreetMap integration.
- **Screens**: `SplashScreen`, `LoginScreen`, `HomeScreen`, `WorkerListScreen`, `WorkerProfileScreen`, `BookingFlowScreen`, `TrackingScreen`, `BookingHistoryScreen`, `CustomerProfileScreen`.
- **Theme & Design System**: Warm ivory canvas (`AppColors.bg`), Forest Teal primary (`AppColors.teal`), Vivid Orange emergency CTA (`AppColors.orange`).
