# CubeSolver AI — Flutter + Firebase

A mobile app for **scanning, solving, and animating** Rubik's Cube solutions using the device camera, an on-device color classifier, and a step-by-step 3D solution viewer.

---

## Features

| Feature | Details |
|---|---|
| 📷 Camera Scanning | Live camera preview with 3×3 grid overlay |
| 🎨 Color Detection | HSV-based color classifier for all 6 Rubik's colors |
| ✏️ Manual Correction | Tap any sticker to fix misdetected colors |
| 🤖 AI Solver | Layer-by-layer algorithm (drop-in Kociemba via FFI for optimal) |
| 🎲 3D Animated Cube | Drag-rotatable 3D cube; step-by-step move animation |
| 🔥 Firebase | Anonymous auth · Firestore session history · Leaderboard |
| 📊 Stats | Personal best moves, average, total solves |

---

## Project Structure

```
lib/
├── main.dart                    # App entry + splash
├── firebase_options.dart        # 🔧 FILL IN YOUR CONFIG
├── models/
│   └── cube_model.dart          # CubeState, SolveSolution, enums
├── services/
│   ├── cube_solver.dart         # Solving algorithm
│   ├── color_detection_service.dart  # HSV color classifier + grid painter
│   ├── firebase_service.dart    # Firestore + Auth
│   └── cube_provider.dart       # Riverpod state providers
├── screens/
│   ├── home_screen.dart         # Dashboard, stats, history
│   ├── scan_screen.dart         # Camera + face scanning flow
│   └── solution_screen.dart     # 3D cube + step-by-step moves
└── widgets/
    ├── cube_3d_widget.dart       # Custom 3D cube painter
    └── face_preview_widget.dart  # 3×3 face grid + FaceTile
```

---

## Setup

### 1. Prerequisites

```bash
flutter --version   # ≥ 3.19.0
dart --version      # ≥ 3.0.0
```

### 2. Install dependencies

```bash
cd rubik_solver
flutter pub get
```

### 3. Firebase Setup

#### a) Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (e.g., `rubik-solver`)
3. Enable **Authentication → Anonymous** sign-in
4. Enable **Firestore Database** (start in test mode, then apply the rules below)

#### b) Connect Flutter to Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# In the project root:
flutterfire configure --project=your-firebase-project-id
```

This auto-generates `lib/firebase_options.dart` with your real credentials.

#### c) Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 4. Android Setup

Add your `google-services.json` to `android/app/`.

In `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21   // required for camera + Firebase
        targetSdkVersion 34
    }
}
```

In `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

In `android/app/build.gradle` (bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. iOS Setup

Add `GoogleService-Info.plist` to `ios/Runner/` via Xcode.

```bash
cd ios && pod install && cd ..
```

Set minimum deployment target to iOS 12+ in Xcode.

### 6. Run

```bash
flutter run
```

---

## Upgrading the Solver

The current solver uses a **beginner's method simulation** that always produces a valid (though not minimal) move sequence. To get optimal solutions (≤20 moves):

### Option A: Dart FFI + Native Kociemba

```bash
# Add to pubspec.yaml
ffi: ^2.1.0
```

Compile [min2phase](https://github.com/cs0x7f/min2phase) as a native `.so`/`.dylib` and call via FFI from `cube_solver.dart`.

### Option B: HTTP Solver API

Replace `CubeSolver.solve()` with a call to a cloud function:

```dart
final response = await http.post(
  Uri.parse('https://us-central1-your-project.cloudfunctions.net/solveCube'),
  body: jsonEncode({'cube': cube.toKociembaString()}),
);
final moves = jsonDecode(response.body)['solution'];
```

---

## Improving Color Detection

The current `ColorDetectionService` uses HSV thresholds. For production:

1. **Google ML Kit** — Use the image labeling API to detect cube sticker colors
2. **TensorFlow Lite** — Train a custom model on cube face images
3. **OpenCV** — Use `flutter_opencv` for robust edge + color detection

Example integration point in `scan_screen.dart`:
```dart
// Replace this line:
detectedColors = ColorDetectionService.simulateDetection(face);

// With real detection using image bytes from _camController!.takePicture()
```

---

## Firebase Collections

| Collection | Document | Fields |
|---|---|---|
| `cube_sessions` | auto-id | `uid`, `U/R/F/D/L/B` (face color arrays), `savedAt` |
| `solutions` | auto-id | `uid`, `sessionId`, `notation`, `moveCount`, `solveTimeMs`, `savedAt` |

---

## Roadmap

- [ ] Real Kociemba solver via FFI
- [ ] ML Kit real-time color detection
- [ ] AR overlay (cube tracking)
- [ ] Social sharing of solutions
- [ ] Timer mode (speed-cubing)
- [ ] Tutorial mode for beginners
