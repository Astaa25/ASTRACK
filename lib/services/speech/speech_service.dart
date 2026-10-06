import 'speech_stub.dart' if (dart.library.html) 'speech_web.dart';

class SpeechService {
  static bool get isSupported => PlatformSpeechService.isSupported;

  static bool startListening({
    required Function(String) onResult,
    required void Function() onEnd,
    Function(String)? onError,
  }) {
    return PlatformSpeechService.startListening(
      onResult: onResult,
      onEnd: onEnd,
      onError: onError,
    );
  }

  static String stopListening() {
    return PlatformSpeechService.stopListening();
  }

  static String getCurrentTranscript() {
    return PlatformSpeechService.getCurrentTranscript();
  }
}
