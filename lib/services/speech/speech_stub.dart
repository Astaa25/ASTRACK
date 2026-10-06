import 'dart:ui';

class PlatformSpeechService {
  static bool get isSupported => false;

  static bool startListening({
    required Function(String) onResult,
    required VoidCallback onEnd,
    Function(String)? onError,
  }) =>
      false;

  static String stopListening() => '';

  static String getCurrentTranscript() => '';
}
