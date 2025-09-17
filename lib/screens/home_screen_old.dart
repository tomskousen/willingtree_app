import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'big_branch_screen.dart';
import 'game_timer_widget.dart';
import 'pairing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My WillingTrees'),
        actions: [
          TextButton(
            onPressed: () async {
              await gameState.logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Show timer if game is active
            if (gameState.timerStarted)
              GameTimerWidget(timeRemaining: gameState.timeRemaining),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Show current user info
                  if (gameState.currentUser != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Logged in as:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                          Text(
                            gameState.currentUser!.phoneNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (gameState.partner != null) ...[
                            const SizedBox(height: 10),
                            const Text(
                              'Paired with:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            Text(
                              gameState.partner!.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // Existing trees
                  for (var tree in gameState.trees)
                    TreeCard(tree: tree),

                  // Add new tree button or show pairing button
                  InkWell(
                    onTap: () {
                      if (gameState.partner == null) {
                        // No partner yet, show pairing screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PairingScreen()),
                        );
                      } else {
                        // Already have partner, start new game
                        final newTree = WillingTree(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          partnerId: gameState.partner!.id,
                          partnerName: gameState.partner!.phoneNumber,
                        );
                        gameState.activeTree = newTree;
                        gameState.trees.add(newTree);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BigBranchScreen(tree: newTree)),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Text(
                            gameState.partner == null ? '🤝' : '+',
                            style: const TextStyle(fontSize: 36, color: AppTheme.textLight),
                          ),
                          Text(
                            gameState.partner == null
                                ? 'Pair with your WillingTree partner'
                                : 'Start new WillingTree game',
                            style: const TextStyle(color: AppTheme.textLight),
                          ),
                          if (gameState.partner != null)
                            Text(
                              '(${3 - gameState.trees.length} of 3 slots available)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class TreeCard extends StatelessWidget {
  final WillingTree tree;

  const TreeCard({super.key, required this.tree});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BigBranchScreen(tree: tree),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You & ${tree.partnerName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Week ${(tree.totalFruit ~/ 3) + 1} • ${tree.myPoints + tree.partnerPoints} points',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            Text(
              '🍎 ${tree.totalFruit} fruit harvested',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class InvitePartnerScreen extends StatelessWidget {
  const InvitePartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Pairing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite Your WillingTree Partner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send an invitation to create your WillingTree',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 30),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Partner\'s Phone or Email',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Send Invitation'),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Or share your pairing code:',
              style: TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'WT-3A9K2',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Share Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<GameState>().isPremium;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: Colors.grey,
      currentIndex: 0,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.gamepad),
          label: 'Game',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.park),
          label: 'Trees',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Scores',
        ),
        BottomNavigationBarItem(
          icon: Icon(isPremium ? Icons.insights : Icons.lock),
          label: 'Insights',
        ),
      ],
    );
  }
}