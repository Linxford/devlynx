import 'package:flutter/material.dart';
import '../../utils/error_logger.dart';

class ErrorToast extends StatelessWidget {
  const ErrorToast({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ErrorLogger.error,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: Colors.red[600],
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
