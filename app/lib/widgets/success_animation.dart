import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessAnimation extends StatelessWidget {
  final String message;
  final VoidCallback onComplete;

  const SuccessAnimation({
    super.key,
    required this.message,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), onComplete);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎉 Lottie Success Animation
            Lottie.asset(
              'assets/animations/success.json',
              width: 150,
              height: 150,
              repeat: false,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if animation not found
                return const Icon(Icons.check_circle, size: 100, color: Colors.green);
              },
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
