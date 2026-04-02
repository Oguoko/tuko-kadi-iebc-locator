# Tuko Kadi IEBC Locator

Flutter app to help Kenyans find nearest IEBC registration offices.

## Production configuration notes

### API key audit and separation
- **Google Places API (Dart HTTP calls):**
  - Uses `--dart-define=GOOGLE_PLACES_API_KEY=...`.
  - Read in `GooglePlacesService` from `String.fromEnvironment('GOOGLE_PLACES_API_KEY')`.
  - Also supports fallback defines `GOOGLE_MAPS_API_KEY` and legacy `MAPS_API_KEY` to avoid production key-name mismatches.
- **Google Maps JavaScript API (Flutter web map runtime):**
  - Loaded at app startup via `loadGoogleMapsApiForWeb()`.
  - Reads `GOOGLE_MAPS_API_KEY`, then `MAPS_API_KEY`, then `GOOGLE_PLACES_API_KEY` as fallback.
- **Google Maps SDK for Android (Manifest meta-data):**
  - Uses Gradle placeholder `${MAPS_API_KEY}` in `AndroidManifest.xml`.
  - Value is resolved in `android/app/build.gradle.kts` from either:
    1. Gradle property `MAPS_API_KEY`, or
    2. Environment variable `MAPS_API_KEY`.
- **Firebase (FlutterFire options):**
  - Web and Android options are separately defined in `lib/firebase_options.dart`.
  - Each Firebase option can be overridden with platform-specific `--dart-define` values:
    - `FIREBASE_WEB_*`
    - `FIREBASE_ANDROID_*`

### Keep local-only secrets out of git
Use one of these local-only approaches for Android maps key:

1. **Environment variable (recommended for CI/local shells)**  
   ```bash
   export MAPS_API_KEY="your-android-maps-key"
   flutter run
   ```

2. **User-level Gradle properties (`~/.gradle/gradle.properties`)**  
   ```properties
   MAPS_API_KEY=your-android-maps-key
   ```

For Places + Firebase overrides:
```bash
flutter run \
  --dart-define=GOOGLE_PLACES_API_KEY=your-places-key \
  --dart-define=GOOGLE_MAPS_API_KEY=your-web-maps-key \
  --dart-define=FIREBASE_WEB_API_KEY=your-web-firebase-key \
  --dart-define=FIREBASE_ANDROID_API_KEY=your-android-firebase-key
```
