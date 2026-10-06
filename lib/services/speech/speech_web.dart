import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class PlatformSpeechService {
  static StreamSubscription? _resultSub;
  static StreamSubscription? _endSub;

  static bool get isSupported {
    try {
      final res = js.context['SpeechRecognition'] != null ||
          js.context['webkitSpeechRecognition'] != null;
      return res;
    } catch (_) {
      return false;
    }
  }

  static bool startListening({
    required Function(String) onResult,
    required VoidCallback onEnd,
    Function(String)? onError,
  }) {
    try {
      _resultSub?.cancel();
      _endSub?.cancel();

      _resultSub = html.window.on['astrack_speech_result'].listen((event) {
        if (event is html.CustomEvent && event.detail != null) {
          onResult(event.detail.toString());
        }
      });

      _endSub = html.window.on['astrack_speech_end'].listen((event) {
        onEnd();
      });

      final speechObj = js.context['ASTRACK_SPEECH'];
      if (speechObj != null) {
        final started = speechObj.callMethod('start', ['id-ID']);
        return started == true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting speech service: $e');
      if (onError != null) onError(e.toString());
      return false;
    }
  }

  static String stopListening() {
    try {
      _resultSub?.cancel();
      _endSub?.cancel();
      _resultSub = null;
      _endSub = null;

      final speechObj = js.context['ASTRACK_SPEECH'];
      if (speechObj != null) {
        final res = speechObj.callMethod('stop');
        return res?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error stopping speech service: $e');
    }
    return '';
  }

  static String getCurrentTranscript() {
    try {
      final speechObj = js.context['ASTRACK_SPEECH'];
      if (speechObj != null) {
        final res = speechObj.callMethod('getTranscript');
        return res?.toString() ?? '';
      }
    } catch (_) {}
    return '';
  }
}
