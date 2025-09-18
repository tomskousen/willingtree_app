import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'game_timer_widget.dart';
import 'guessing_screen.dart';

class TimerWaitingScreen extends StatefulWidget {
  final WillingTree tree;

  const TimerWaitingScreen({super.key, required this.tree});

  @override
  State<TimerWaitingScreen> createState() => _TimerWaitingScreenState();
}

class _TimerWaitingScreenState extends State<TimerWaitingScreen> {
  void _finishEarly() {
    // Navigate directly to guessing screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GuessingScreen(tree: widget.tree),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Intentions Are Set'),
      ),
      body: Column(
        children: [
          // Timer widget
          GameTimerWidget(timeRemaining: gameState.timeRemaining),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tree icon
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.park,
                      size: 80,
                      color: AppTheme.primaryGreen,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Your Little Branch is Growing!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'You\'ve committed to supporting ${gameState.partner?.displayName ?? "your partner"} in meaningful ways.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Encouragement box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pro Tip',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take a moment to identify exactly when and in what setting you intend to achieve the most important item for you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Being specific about your intentions increases the likelihood of follow-through!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Progress indicator
                  Column(
                    children: [
                      Text(
                        'Time remaining: ${_formatDuration(gameState.timeRemaining)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _calculateProgress(gameState.timeRemaining),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Ready to celebrate the attention you\'ve given and received?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _finishEarly,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                    child: const Text(
                      'I\'m Ready to Connect',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Or wait for the timer to complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 24) {
      final days = hours ~/ 24;
      final remainingHours = hours % 24;
      return '$days days, $remainingHours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }

  double _calculateProgress(Duration remaining) {
    const totalDuration = Duration(hours: 144); // 6 days
    final elapsed = totalDuration - remaining;
    return elapsed.inSeconds / totalDuration.inSeconds;
  }
}