# Flutter Mobile App Setup Guide

## Prerequisites

- Flutter SDK 3.0 or higher
- Android Studio (for Android development)
- Xcode (for iOS development, Mac only)
- VS Code or Android Studio IDE

## Installation

### 1. Install Flutter

Follow the official guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Install Dependencies

```bash
cd mobile
flutter pub get
```

### 3. Configure Backend URL

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // For Android Emulator, use 10.0.2.2
  // For iOS Simulator, use localhost
  // For real device, use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // ... rest of the config
}
```

**Important**: Update the baseUrl based on your setup:
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Real Device: `http://YOUR_COMPUTER_IP:8000` (e.g., `http://192.168.1.100:8000`)

## Running the App

### Android

```bash
# List available devices
flutter devices

# Run on connected device/emulator
flutter run

# Run in release mode
flutter run --release
```

### iOS (Mac only)

```bash
# Open iOS simulator
open -a Simulator

# Run app
flutter run
```

### Web

```bash
# Enable web support (one time)
flutter config --enable-web

# Run on Chrome
flutter run -d chrome

# Run on Edge
flutter run -d edge
```

## Building for Production

### Android APK

```bash
# Build release APK
flutter build apk --release

# Build split APKs (smaller size)
flutter build apk --split-per-abi --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (Mac only)

```bash
flutter build ios --release

# Then open Xcode to archive and upload
open ios/Runner.xcworkspace
```

### Web

```bash
flutter build web --release

# Output: build/web/
# Deploy this folder to your web server
```

## Project Structure

```
mobile/
├── lib/
│   ├── config/
│   │   └── app_config.dart          # App configuration
│   ├── models/
│   │   └── models.dart               # Data models
│   ├── services/
│   │   └── api_service.dart          # API client
│   ├── screens/
│   │   ├── login_screen.dart         # Login page
│   │   ├── dashboard_screen.dart     # Dashboard
│   │   ├── students_list_screen.dart # Students list
│   │   ├── student_profile_screen.dart # Student profile
│   │   └── analytics_screen.dart     # Analytics
│   └── main.dart                     # App entry point
├── pubspec.yaml                      # Dependencies
└── README.md                         # This file
```

## Features

### Implemented
- ✅ JWT Authentication
- ✅ Dashboard with statistics
- ✅ Student list with search
- ✅ Student 360° profile
- ✅ Marks, attendance, activities display
- ✅ AI risk prediction
- ✅ Interactive charts
- ✅ Responsive UI
- ✅ Marks entry form
- ✅ Attendance entry form
- ✅ Activity management
- ✅ PDF & Excel export

### Future Enhancements
- ⏳ Push notifications
- ⏳ Offline mode support

## Testing

### Run Tests

```bash
flutter test
```

### Run on Multiple Devices

```bash
# Run on all connected devices
flutter run -d all
```

## Troubleshooting

### Issue: "Unable to connect to backend"

**Solutions**:
1. Ensure backend is running on port 8000
2. Check baseUrl in app_config.dart
3. For Android emulator, use 10.0.2.2 instead of localhost
4. For real device, use computer's IP address
5. Ensure device and computer are on same network

### Issue: "Gradle build failed"

**Solutions**:
1. Update Android SDK
2. Run `flutter clean` then `flutter pub get`
3. Check Android Studio is properly installed

### Issue: "CocoaPods not installed" (iOS)

**Solutions**:
```bash
sudo gem install cocoapods
cd ios
pod install
```

### Issue: Charts not displaying

**Solutions**:
1. Ensure fl_chart package is installed
2. Run `flutter pub get`
3. Restart the app

## Customization

### Change App Name

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:label="Your App Name">
```

Edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleName</key>
<string>Your App Name</string>
```

### Change App Icon

1. Add your icon to `assets/icon/icon.png`
2. Install flutter_launcher_icons:
```bash
flutter pub add dev:flutter_launcher_icons
```
3. Configure in pubspec.yaml and run:
```bash
flutter pub run flutter_launcher_icons
```

### Change Theme Colors

Edit `lib/main.dart`:
```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.purple, // Change this
  ),
)
```

## Performance Tips

1. Use `const` constructors where possible
2. Avoid rebuilding entire widget trees
3. Use `ListView.builder` for long lists
4. Implement pagination for large datasets
5. Cache images and data locally
6. Use release mode for testing performance

## Deployment

### Android Play Store

1. Create keystore for signing
2. Configure signing in android/app/build.gradle
3. Build app bundle: `flutter build appbundle`
4. Upload to Play Console

### iOS App Store

1. Configure signing in Xcode
2. Build: `flutter build ios`
3. Archive in Xcode
4. Upload to App Store Connect

### Web Hosting

1. Build: `flutter build web`
2. Upload `build/web/` to hosting service
3. Configure CORS if needed
4. Use HTTPS for production

## Support

For Flutter issues:
- Official Docs: https://docs.flutter.dev
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

For EduPulse specific issues:
- Check backend is running
- Verify API endpoints
- Check network connectivity
