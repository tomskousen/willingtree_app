import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'pairing_screen.dart';
import 'big_branch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check for invite code in URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameState>().checkForInviteCode();
    });
  }

  void _startNewGame(BuildContext context, GameState gameState) {
    // Create a deterministic tree ID based on both user IDs
    // Sort the IDs to ensure both users get the same tree ID
    final userId1 = gameState.currentUser!.id;
    final userId2 = gameState.partner!.id;
    final sortedIds = [userId1, userId2]..sort();

    // Create tree ID from sorted user IDs and current date
    final dateStr = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final treeId = 'tree_${sortedIds[0]}_${sortedIds[1]}_$dateStr';

    print('Creating/joining tree with ID: $treeId');
    print('Current user: $userId1');
    print('Partner: $userId2');

    final newTree = WillingTree(
      id: treeId,
      partnerId: gameState.partner!.id,
      partnerName: gameState.partner!.displayName ?? gameState.partner!.phoneNumber,
    );
    gameState.activeTree = newTree;
    gameState.trees.add(newTree);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BigBranchScreen(tree: newTree),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WillingTree'),
        actions: [
          TextButton(
            onPressed: () async {
              await gameState.logout();
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User info card
              if (gameState.currentUser != null)
                Card(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              gameState.currentUser!.displayName ?? gameState.currentUser!.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (gameState.partner != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Paired with ${gameState.partner!.displayName ?? gameState.partner!.phoneNumber}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Main action button
              SizedBox(
                width: double.infinity,
                height: 120,
                child: ElevatedButton(
                  onPressed: () {
                    if (gameState.partner == null) {
                      // No partner yet, show pairing screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PairingScreen(),
                        ),
                      );
                    } else {
                      // Have partner, start new game
                      _startNewGame(context, gameState);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gameState.partner == null ? '🤝' : '🌳',
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        gameState.partner == null
                            ? 'Pair with your WillingTree partner'
                            : 'Start new WillingTree game',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'How to use:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameState.partner == null
                          ? '1. Share your pairing code with your partner\n2. Or enter their code to connect\n3. Start playing WillingTree together!'
                          : '1. Create your Big Limb (wants/needs)\n2. Select Little Branches (willing to do)\n3. Score points and grow your relationship!',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}