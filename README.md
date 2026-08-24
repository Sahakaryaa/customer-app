# 🏠 Sahakarya — Customer App (Flutter)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Cooperative Gig Services Marketplace — Customer Mobile Client**  
> Connects households and businesses to vetted, certified **Labour Cooperative Federation** workers (electricians, plumbers, cleaners, painters, carpenters, caregivers) with transparent pricing and zero exploitative commissions.

---

## 🌟 Key Features

* **Geospatial Worker Discovery:** Real-time search of certified cooperative professionals within a customizable radius using MongoDB 2dsphere geo-indexing.
* **Instant & Transparent Booking:** Upfront cooperative pricing with clear itemized breakdowns (Labour Rate + Fair Commission + Worker Welfare Fund contribution).
* **Live Job Tracking & Status Stepper:** Real-time Socket.IO and WebSocket updates from dispatch to arrival, in-progress work, and completion.
* **Cooperative Quality Badges:** Institutional verification badges representing certified skills, background checks, and federation membership.
* **Rating & Feedback System:** Multi-dimensional feedback system scoring punctuality, quality, and cooperative professionalism.
* **Multi-Language Support Ready:** Clean UI architecture built for multi-regional accessibility.

---

## 🏗️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev) (iOS, Android, Web)
* **State Management:** [Riverpod](https://riverpod.dev)
* **Navigation & Routing:** [GoRouter](https://pub.dev/packages/go_router)
* **Networking & REST:** `http` with custom resilient `ApiClient`
* **Real-time Comms:** `socket_io_client` & WebSocket event streams
* **Design System:** Custom theme with modern typography, cooperative brand tokens, and responsive widgets.

---

## 📂 Project Structure

```text
customer_app/
├── lib/
│   ├── main.dart                      # App entry point & provider initialization
│   ├── router.dart                     # Declarative GoRouter routing configuration
│   ├── models/                         # Data transfer models (User, Worker, Booking, Location)
│   ├── providers/                      # Riverpod state notifiers & business logic
│   │   ├── auth_provider.dart          # Authentication & session state
│   │   ├── booking_provider.dart       # Active and historical booking states
│   │   └── nearby_workers_provider.dart# Geospatial worker search state
│   ├── screens/                        # UI Screens & page flows
│   │   ├── auth/                       # Login & Customer Registration
│   │   ├── home/                       # Category discovery & quick bookings
│   │   ├── worker_discovery/           # Geospatial worker listing & profiles
│   │   ├── booking_flow/               # Schedule, address, and checkout
│   │   ├── live_tracking/              # Real-time worker tracking & status stepper
│   │   ├── payment/                    # Settlement & welfare fund breakdown
│   │   ├── rating/                     # Star ratings & review submission
│   │   └── profile/                    # Profile settings & booking history
│   ├── services/                       # API clients, WebSockets, & Location handlers
│   ├── theme/                          # Color palettes, dark/light styles, typography
│   └── widgets/                        # Reusable UI components & badges
└── pubspec.yaml                        # Dependencies and assets
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`>= 3.3.0`)
* Dart SDK (`>= 3.0.0`)
* Android Studio / Xcode / VS Code with Flutter extensions

### Installation & Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sahakaryaa/Customer-App.git
   cd Customer-App
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Backend Endpoint:**
   Create or verify `.env` (or configure in `lib/services/api_client.dart`):
   ```env
   API_BASE_URL=http://10.0.2.2:8000  # Android Emulator loopback
   # API_BASE_URL=http://localhost:8000 # iOS Simulator or Web
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 🤝 Labour Cooperative Federation Impact

Unlike private platforms that charge 20–30% commissions, this platform routes **5%–10%** directly to the Labour Federation to administer retirement pensions, health cover, and child education benefits for workers.
