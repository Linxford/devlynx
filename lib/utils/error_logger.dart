import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';
// import 'package:flutter/material.dart';

class ErrorLogger {
  static final ValueNotifier<String?> error = ValueNotifier(null);

  static void log(String message) {
    debugPrint('⚠️ Error: $message');
    error.value = message;
    // VoiceService.announceError(message); // 🗣️ - Method not implemented
    Future.delayed(const Duration(seconds: 5), () => error.value = null);
  }

  static void setupGlobalHandlers() {
    FlutterError.onError = (details) {
      log(details.exceptionAsString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      log(error.toString());
      return true;
    };
  }
}
