import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'big_branch_screen.dart';
import 'profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  final int initialIndex;
  final WillingTree? activeTree;

  const MainAppScreen({
    super.key,
    this.initialIndex = 0,
    this.activeTree,
  });

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex;
  WillingTree? _activeTree;
  Timer? _pairingCheckTimer;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _activeTree = widget.activeTree;

    // If no active tree provided, check GameState for active tree
    if (_activeTree == null) {
      final gameState = context.read<GameState>();
      _activeTree = gameState.activeTree;

      // Start checking for pairing if no tree and user has partner
      if (_activeTree == null && gameState.partner != null) {
        _startTreeCheck();
      }
    }
  }

  @override
  void didUpdateWidget(MainAppScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update active tree if it changed
    if (widget.activeTree != oldWidget.activeTree) {
      setState(() {
        _activeTree = widget.activeTree;
      });
    }
    // Update selected index if it changed
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
    }
  }

  void _startTreeCheck() {
    // Check periodically if partner has started a tree
    _pairingCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final gameState = context.read<GameState>();

      // Check if partner has created a tree we should join
      if (gameState.partner != null && _activeTree == null) {
        // Create matching tree ID to check if partner started game
        final userId1 = gameState.currentUser!.id;
        final userId2 = gameState.partner!.id;
        final sortedIds = [userId1, userId2]..sort();
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final treeId = 'tree_${sortedIds[0]}_${sortedIds[1]}_$dateStr';

        // Check if this tree exists in our list
        final existingTree = gameState.trees.firstWhere(
          (t) => t.id == treeId,
          orElse: () => WillingTree(
            id: treeId,
            partnerId: gameState.partner!.id,
            partnerName: gameState.partner!.displayName ?? gameState.partner!.phoneNumber,
          ),
        );

        // If we don't have the tree yet, create it and navigate
        if (!gameState.trees.any((t) => t.id == treeId)) {
          setState(() {
            _activeTree = existingTree;
            gameState.activeTree = existingTree;
            gameState.trees.add(existingTree);
            _selectedIndex = 1; // Switch to Tree tab
          });
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _pairingCheckTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    // Use activeTree from state or fallback to gameState's activeTree
    final currentTree = _activeTree ?? gameState.activeTree;

    // Define the screens
    final List<Widget> _screens = [
      const HomeScreen(),
      currentTree != null
        ? BigBranchScreen(tree: currentTree)
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.park_outlined,
                  size: 80,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No active tree yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // Go to home to start a tree
                    });
                  },
                  child: const Text('Start a Tree'),
                ),
              ],
            ),
          ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.park_outlined),
                  if (currentTree != null && gameState.timeRemaining.inHours > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: const Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  const Icon(Icons.park),
                  if (_activeTree != null && gameState.timeRemaining.inHours > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: const Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Tree',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textLight,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}