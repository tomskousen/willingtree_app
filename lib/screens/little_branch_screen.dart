import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/game_sync_service.dart';
import 'game_timer_widget.dart';
import 'timer_waiting_screen.dart';

class LittleBranchScreen extends StatefulWidget {
  final WillingTree tree;

  const LittleBranchScreen({super.key, required this.tree});

  @override
  State<LittleBranchScreen> createState() => _LittleBranchScreenState();
}

class _LittleBranchScreenState extends State<LittleBranchScreen> {
  List<WantItem> partnerBigBranch = [];
  List<WantItem> shuffledItems = [];
  WantItem? randomItem;
  final Set<String> selectedItems = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerBigBranch();
  }

  void _loadPartnerBigBranch() {
    final gameState = context.read<GameState>();

    print('Loading partner Big Branch...');
    print('Tree ID: ${widget.tree.id}');
    print('Partner ID: ${gameState.partner!.id}');

    // Get partner's Big Branch from shared storage
    final partnerItems = GameSyncService.getPartnerBigBranch(
      widget.tree.id,
      gameState.partner!.id,
    );

    print('Partner items loaded: ${partnerItems?.length ?? 0} items');

    if (partnerItems != null && partnerItems.isNotEmpty) {
      setState(() {
        partnerBigBranch = partnerItems;

        // Select 1 random item
        final random = Random();
        randomItem = partnerItems[random.nextInt(partnerItems.length)];
        print('Random item selected: ${randomItem!.description}');

        // Shuffle remaining items for selection (excluding the random one)
        final remainingItems = partnerItems
            .where((item) => item.id != randomItem!.id)
            .toList();
        remainingItems.shuffle();

        // Take first 6 for selection
        shuffledItems = remainingItems.take(6).toList();
        print('Items available for selection: ${shuffledItems.length}');

        isLoading = false;
      });
    } else {
      // Partner hasn't completed yet - this shouldn't happen if we're navigating correctly
      print('ERROR: Partner Big Branch not found!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Partner data not found. Going back...'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate back to Big Branch screen
      Navigator.pop(context);
    }
  }

  void _toggleItem(String itemId) {
    setState(() {
      if (selectedItems.contains(itemId)) {
        selectedItems.remove(itemId);
      } else if (selectedItems.length < 2) {
        selectedItems.add(itemId);
      }
    });
  }

  void _submitLittleBranch() {
    if (selectedItems.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select exactly 2 items'),
        ),
      );
      return;
    }

    final gameState = context.read<GameState>();

    // Create Little Branch list (1 random + 2 selected)
    final littleBranch = <WantItem>[
      randomItem!,
      ...shuffledItems.where((item) => selectedItems.contains(item.id)),
    ];

    // Save to tree
    widget.tree.myLittleBranches = littleBranch;

    // Sync to shared storage (without points!)
    GameSyncService.storeLittleBranch(
      widget.tree.id,
      gameState.currentUser!.id,
      littleBranch,
    );

    // Navigate to timer/waiting screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TimerWaitingScreen(tree: widget.tree),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select from ${gameState.partner?.displayName ?? "Partner"}\'s Big Branch'),
      ),
      body: Column(
        children: [
          // Timer widget
          GameTimerWidget(timeRemaining: gameState.timeRemaining),

          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Your Little Branch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'What are you willing to do for ${gameState.partner?.displayName ?? "your partner"}?',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• 1 item was randomly selected (marked below)',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Choose 2 more items you\'re willing to focus on',
                          style: TextStyle(fontSize: 12),
                        ),
                        const Text(
                          '• Points are hidden during selection',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Random item (pre-selected)
                  if (randomItem != null) ...[
                    const Text(
                      'Randomly Selected:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.amber.shade50,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.casino, color: Colors.white),
                        ),
                        title: Text(randomItem!.description),
                        subtitle: const Text('Automatically included'),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Selectable items
                  Text(
                    'Choose 2 items (${selectedItems.length}/2 selected):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...shuffledItems.map((item) {
                    final isSelected = selectedItems.contains(item.id);
                    return Card(
                      color: isSelected
                          ? AppTheme.primaryGreen.withOpacity(0.1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey,
                          child: Icon(
                            isSelected ? Icons.check : Icons.circle_outlined,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(item.description),
                        subtitle: Text(
                          isSelected
                              ? 'Selected for your Little Branch'
                              : 'Tap to select',
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textLight,
                          ),
                        ),
                        onTap: () => _toggleItem(item.id),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

          // Submit button
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedItems.length == 2 ? _submitLittleBranch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedItems.length == 2
                      ? AppTheme.primaryGreen
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  selectedItems.length == 2
                      ? 'Lock In Little Branch'
                      : 'Select ${2 - selectedItems.length} more item${selectedItems.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}