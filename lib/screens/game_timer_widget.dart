import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GameTimerWidget extends StatelessWidget {
  final Duration timeRemaining;

  const GameTimerWidget({super.key, required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    final seconds = timeRemaining.inSeconds % 60;

    Color bgColor = const Color(0xFFFFE0B2);
    String message = 'Time remaining this round:';

    if (hours < 24) {
      bgColor = const Color(0xFFFFCCBC);
      message = 'Less than 24 hours left!';
    }

    if (hours == 0 && minutes == 0 && seconds == 0) {
      bgColor = const Color(0xFFFF5252);
      message = 'TIME\'S UP! Start guessing!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      color: bgColor,
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const Text(
            '144-hour countdown',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}