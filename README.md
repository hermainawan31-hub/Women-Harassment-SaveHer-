
  # SafeHer

  **A silent emergency alert app for women's safety in Pakistan.**

  Built with Flutter + Firebase — one tap sends your live location, an SOS message, and audio evidence straight to your trusted contacts.



---

## Why SafeHer

In a real harassment or threat situation, a victim doesn't have minutes — she has seconds. But calling for help traditionally means unlocking the phone, opening contacts, finding the right number, dialing, waiting, and explaining the situation and location out loud. That's too slow, and often not possible at all.

**SafeHer collapses that entire process into a single tap** — from a persistent notification or a home-screen widget — automatically capturing your location, messaging your emergency contacts, and recording audio, with no need to navigate the app.

## Features

| Feature | Description |
|---|---|
| 🔐 **Authentication** | Email/password sign in & sign up, backed by Firebase Auth |
| 🆘 **One-Tap SOS** | Trigger an alert from a persistent notification or a home-screen widget — no need to open the app |
| 📍 **Live Location Sharing** | Real-time GPS + human-readable address, shown on an interactive map |
| 👥 **Emergency Contacts** | Save up to 3 trusted contacts who receive your SOS alerts |
| 🎙️ **Incident Audio Recording** | Automatically records audio when SOS is active, saved as evidence |
| 🕘 **SOS History** | Every alert is logged with a timestamp and location for later reference |
| 🩹 **Safety Profile** | Store medical info (blood group, emergency notes) so responders know who they're helping |
| 📖 **Safety Tips** | In-app guidance content for staying safe |
| 🔔 **Always-On Protection** | A persistent notification keeps the SOS action within one tap at all times |

### 🚧 Roadmap

- **Lock-screen SOS trigger** — a volume-key press pattern that fires an alert even when the phone is fully locked and the app is closed, using a native Android Accessibility Service and a headless background engine. In active development.

## How It Works

1. User taps the SafeHer notification or the home-screen widget.
2. The app captures the user's current GPS location and reverse-geocodes it into a readable address.
3. An SOS event is logged to the user's history in Firestore.
4. An SMS with the location and a live map link is sent to all saved emergency contacts.
5. Audio recording starts automatically to capture what's happening.

## Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **Backend**: [Firebase](https://firebase.google.com) — Authentication, Cloud Firestore, Cloud Storage
- **Location**: `geolocator`, `geocoding`, `flutter_map` + `latlong2`
- **Messaging**: `url_launcher` (SMS), `share_plus` (fallback share sheet)
- **Notifications**: `flutter_local_notifications`
- **Audio**: `record`, `audioplayers`, `path_provider`
- **Media**: `image_picker`, `firebase_storage`
- **Permissions**: `permission_handler`

## Project Structure

```
lib/
├── main.dart                     # App entry point, auth gate, permission requests
├── LoginPage.dart                 # Sign in / sign up
├── home_screen.dart               # Main dashboard + SOS button
├── profile_screen.dart            # User profile & medical info
├── emergency_contacts_screen.dart # Manage trusted contacts
├── live_location.dart             # Live location map & sharing toggle
├── safeher_sos_service.dart       # Core SOS logic (location, Firestore, SMS)
├── sos_history_screen.dart        # Past SOS event log
├── sos_notification_service.dart  # Persistent protection notification
├── sos_recording_service.dart     # Audio recording during SOS
├── safety_tips_screen.dart        # Safety guidance content
├── settings_screen.dart           # App settings
├── about_screen.dart              # About / info screen
├── app_colors.dart                # Centralized theme colors
└── firebase_options.dart          # Firebase project configuration

android/
└── app/src/main/kotlin/.../       # Native Android integration (widget, SOS channel)
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.11.4)
- A [Firebase](https://console.firebase.google.com) project with Authentication, Firestore, and Storage enabled
- Android Studio / Xcode for building to a device or emulator

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-username>/Women-Harassment-SaveHer-.git
   cd Women-Harassment-SaveHer-
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at the [Firebase Console](https://console.firebase.google.com).
   - Enable **Authentication** (Email/Password), **Cloud Firestore**, and **Cloud Storage**.
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`, or add your own `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).

4. **Run the app**
   ```bash
   flutter run
   ```

### Required Permissions

SafeHer requests the following permissions on first launch: **Location** (including background), **Microphone**, **Notifications**, and **SMS**. All are required for the SOS flow to work correctly — make sure to grant them when prompted.

## Contributing

Contributions are welcome. Please open an issue to discuss significant changes before submitting a pull request.

## Disclaimer

SafeHer is a personal safety companion tool and is **not a replacement for emergency services**. In a life-threatening situation, always contact local emergency services (Police: **15**, Rescue: **1122**) directly wherever possible.

## License

This project does not yet specify a license. Add one (e.g. MIT, Apache 2.0) before accepting external contributions.
