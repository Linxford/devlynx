import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ErrorLogger {
  static final ValueNotifier<String?> error = ValueNotifier(null);

  static void log(String message) {
    debugPrint('⚠️ Error: $message');
    
    // Use post-frame callback to prevent setState during frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      error.value = message;
      Future.delayed(const Duration(seconds: 5), () {
        if (error.value == message) {
          error.value = null;
        }
      });
    });
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
