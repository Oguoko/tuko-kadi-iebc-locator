import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

const String _mapsWebApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
  ),
);

Future<void> loadGoogleMapsApiForWeb() async {
  if (_mapsWebApiKey.isEmpty) {
    if (kDebugMode) {
      debugPrint(
        'Google Maps JS API key is missing (checked GOOGLE_MAPS_API_KEY, MAPS_API_KEY, GOOGLE_PLACES_API_KEY).',
      );
    }
    return;
  }
  if (kDebugMode) {
    debugPrint('Google Maps JS API key loaded from dart-define (length: ${_mapsWebApiKey.length}).');
  }

  final existingScript = html.document.head?.querySelector(
    'script[src*="maps.googleapis.com/maps/api/js"]',
  );
  if (existingScript != null) {
    return;
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=$_mapsWebApiKey&libraries=places'
    ..async = true
    ..defer = true;

  script.onLoad.first.then((_) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  });

  script.onError.first.then((_) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('Failed to load Google Maps JavaScript API for web.'),
      );
    }
  });

  html.document.head?.append(script);
  await completer.future;
}
