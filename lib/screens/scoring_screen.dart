import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/game_sync_service.dart';
import 'main_app_screen.dart';

class ScoringScreen extends StatefulWidget {
  final WillingTree tree;

  const ScoringScreen({super.key, required this.tree});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  int partnerScore = 0;

  @override
  void initState() {
    super.initState();
    _loadPartnerScore();
  }

  void _loadPartnerScore() {
    final gameState = context.read<GameState>();
    if (gameState.partner != null) {
      partnerScore = GameSyncService.getScore(
        widget.tree.id,
        gameState.partner!.id,
      );

      // If partner hasn't submitted their score yet, calculate it from their perspective
      if (partnerScore == 0 && widget.tree.myLittleBranches.isNotEmpty) {
        // Partner gets points for items we worked on from their Big Branch
        int partnerEffortPoints = 0;
        for (var myChoice in widget.tree.myLittleBranches) {
          // Find matching item in partner's Big Branch to get its point value
          final matchingItem = widget.tree.partnerBigBranch.firstWhere(
            (item) => item.id == myChoice.id,
            orElse: () => myChoice,
          );
          partnerEffortPoints += matchingItem.points;
        }
        widget.tree.partnerPoints = partnerEffortPoints;
        partnerScore = partnerEffortPoints;
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // Calculate week number
    final weekNumber = (widget.tree.totalFruit ~/ 3) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Week $weekNumber Fruit 🍎'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'You & ${widget.tree.partnerName}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Fruit display
                  const Text(
                    '🍎🍎🍎',
                    style: TextStyle(fontSize: 48),
                  ),
                  const Text(
                    'Your fruit harvest!',
                    style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  // Points breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${widget.tree.myPoints}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const Text(
                                'Your Points',
                                style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$partnerScore',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              Text(
                                '${widget.tree.partnerName}\'s Points',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Score breakdown
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 How You Earned Points:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '🎯 Correct Guesses: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Points for guessing what ${widget.tree.partnerName} worked on',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '💪 Partner\'s Efforts: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Points from ${widget.tree.partnerName} working on your wants',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Show what partner worked on
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What ${widget.tree.partnerName} Worked On For You:',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        if (widget.tree.partnerLittleBranches.isEmpty)
                          const Text(
                            'Waiting for partner to complete their week...',
                            style: TextStyle(color: AppTheme.textLight, fontStyle: FontStyle.italic),
                          )
                        else
                          for (var item in widget.tree.partnerLittleBranches)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${item.points} pts',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Premium upsell
                  if (!gameState.isPremium)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.premiumLight, Color(0xFFDEB887)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '🔒',
                            style: TextStyle(fontSize: 36),
                          ),
                          const Text(
                            'Unlock Deep Insights',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Journal prompts, patterns, relationship growth tracking',
                            style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<GameState>().upgradeToPremium();
                            },
                            style: AppTheme.premiumButtonStyle,
                            child: const Text('Upgrade to Premium (\$1/week)'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Update Big Branch and reallocate points
                    widget.tree.phase = GamePhase.updating;
                    // Navigate to MainAppScreen with Tree tab
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MainAppScreen(
                          initialIndex: 1,
                          activeTree: widget.tree,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Update Big Branch for Next Week'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    // Start new week without changes
                    widget.tree.phase = GamePhase.buildingBigBranch;
                    widget.tree.totalFruit += 3;

                    // Reset timer
                    context.read<GameState>().timeRemaining = const Duration(hours: 144);
                    context.read<GameState>().timerStarted = false;

                    // Navigate to MainAppScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainAppScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Keep Same & Play Next Week'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}