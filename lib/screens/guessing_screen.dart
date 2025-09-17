import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'scoring_screen.dart';

class GuessingScreen extends StatefulWidget {
  final WillingTree tree;

  const GuessingScreen({super.key, required this.tree});

  @override
  State<GuessingScreen> createState() => _GuessingScreenState();
}

class _GuessingScreenState extends State<GuessingScreen> {
  int guessesRemaining = 3;
  final List<WantItem> selectedGuesses = [];

  void toggleGuess(WantItem item) {
    setState(() {
      if (selectedGuesses.contains(item)) {
        selectedGuesses.remove(item);
      } else if (selectedGuesses.length < 3) {
        selectedGuesses.add(item);
      }
    });
  }

  void submitGuesses() {
    if (selectedGuesses.isEmpty) return;

    // Calculate points
    int pointsEarned = 0;
    for (var guess in selectedGuesses) {
      if (widget.tree.partnerLittleBranches.any((item) => item.id == guess.id)) {
        // Correct guess! 5 points each
        pointsEarned += 5;
      }
    }

    // Points from partner's efforts on your Big Branch
    int effortPoints = widget.tree.partnerLittleBranches
        .where((item) => widget.tree.myBigBranch.contains(item))
        .fold(0, (sum, item) => sum + item.points);

    widget.tree.myPoints += pointsEarned + effortPoints;

    // Navigate to scoring
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoringScreen(tree: widget.tree),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growing Leaves'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What did ${widget.tree.partnerName} work on?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '3 guesses from YOUR Big Branch (5 pts each)',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🍃 Guesses remaining: ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1976D2)),
                      ),
                      Text(
                        '$guessesRemaining',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Show YOUR Big Branch with points visible for guessing
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.tree.myBigBranch.length,
              itemBuilder: (context, index) {
                final item = widget.tree.myBigBranch[index];
                final isSelected = selectedGuesses.contains(item);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.description} (${item.points} pts)',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => toggleGuess(item),
                        activeColor: AppTheme.primaryGreen,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: selectedGuesses.isNotEmpty ? submitGuesses : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text('Submit Guesses (${selectedGuesses.length} selected)'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    // Show bonus recognition screen (premium feature hint)
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('🌟 Bonus Recognition'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Notice something special that wasn\'t on your list?'),
                            SizedBox(height: 16),
                            Text(
                              '🔒 Premium Feature',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Unlock bonus recognitions with Premium',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('+ Add Bonus Recognition'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}