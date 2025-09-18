import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/game_sync_service.dart';
import 'little_branch_screen.dart';

class BigBranchScreen extends StatefulWidget {
  final WillingTree tree;

  const BigBranchScreen({super.key, required this.tree});

  @override
  State<BigBranchScreen> createState() => _BigBranchScreenState();
}

class _BigBranchScreenState extends State<BigBranchScreen> {
  final List<WantItem> bigBranch = [];
  int pointsRemaining = 25;
  int currentEditIndex = 0;
  final TextEditingController itemController = TextEditingController();
  final TextEditingController pointsController = TextEditingController(text: '1');
  final FocusNode itemFocus = FocusNode();
  Timer? _checkTimer;
  bool isSubmitted = false;
  bool isWaitingForPartner = false;

  @override
  void initState() {
    super.initState();

    // Load existing Big Branch if available
    _loadExistingBigBranch();

    // Check periodically if partner has completed
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkPartnerStatus();
    });

    // Focus on the first input if starting fresh
    if (bigBranch.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        itemFocus.requestFocus();
      });
    }
  }

  void _loadExistingBigBranch() {
    final gameState = context.read<GameState>();

    // First check if the tree already has a Big Branch
    if (widget.tree.myBigBranch.isNotEmpty) {
      setState(() {
        bigBranch.addAll(widget.tree.myBigBranch);
        pointsRemaining = 25 - bigBranch.fold(0, (sum, item) => sum + item.points);
        currentEditIndex = bigBranch.length;
      });
      return;
    }

    // Otherwise try to load from shared storage
    final storedBranch = GameSyncService.getPartnerBigBranch(
      widget.tree.id,
      gameState.currentUser!.id,
    );

    if (storedBranch != null && storedBranch.isNotEmpty) {
      setState(() {
        bigBranch.addAll(storedBranch);
        pointsRemaining = 25 - bigBranch.fold(0, (sum, item) => sum + item.points);
        currentEditIndex = bigBranch.length;
        isSubmitted = bigBranch.length == 12;
        if (isSubmitted) {
          isWaitingForPartner = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    itemController.dispose();
    pointsController.dispose();
    itemFocus.dispose();
    super.dispose();
  }

  void _checkPartnerStatus() {
    if (!mounted) return;

    final gameState = context.read<GameState>();
    if (gameState.partner != null && widget.tree.id.isNotEmpty) {
      print('Checking partner status...');
      print('Tree ID: ${widget.tree.id}');
      print('Current User ID: ${gameState.currentUser!.id}');
      print('Partner ID: ${gameState.partner!.id}');
      print('My Big Branch length: ${bigBranch.length}');

      final bothComplete = GameSyncService.areBothBigBranchesComplete(
        widget.tree.id,
        gameState.currentUser!.id,
        gameState.partner!.id,
      );

      print('Both complete: $bothComplete');

      if (bothComplete && bigBranch.length == 12) {
        print('Both users have completed! Starting timer and navigating...');

        // Cancel the timer to prevent duplicate navigations
        _checkTimer?.cancel();

        // Both complete - start timer and navigate
        GameSyncService.startTimer(widget.tree.id);
        gameState.startTimer();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LittleBranchScreen(tree: widget.tree),
          ),
        );
      }
    }
  }

  void _addCurrentItem() {
    if (itemController.text.isEmpty) return;
    if (bigBranch.length >= 12) return;

    final points = int.tryParse(pointsController.text) ?? 1;
    if (points < 1 || points > pointsRemaining) return;

    setState(() {
      bigBranch.add(WantItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: itemController.text,
        points: points,
      ));
      pointsRemaining -= points;
      currentEditIndex = bigBranch.length;

      // Clear and refocus for next item
      itemController.clear();
      pointsController.text = '1';

      if (bigBranch.length < 12) {
        // Auto-focus on next item
        WidgetsBinding.instance.addPostFrameCallback((_) {
          itemFocus.requestFocus();
        });
      }
    });
  }

  void _updateItemPoints(int index, int newPoints) {
    if (newPoints < 1) return;

    final currentPoints = bigBranch[index].points;
    final difference = newPoints - currentPoints;

    if (pointsRemaining - difference < 0) return;

    setState(() {
      bigBranch[index].points = newPoints;
      pointsRemaining = 25 - bigBranch.fold(0, (sum, item) => sum + item.points);
    });
  }

  void _fillFromPopular() {
    final suggestions = GameSyncService.getPopularSuggestions();
    final needed = 12 - bigBranch.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $needed items'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(suggestions[index]),
                onTap: () {
                  setState(() {
                    bigBranch.add(WantItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description: suggestions[index],
                      points: 1,
                    ));
                    pointsRemaining -= 1;
                  });

                  if (bigBranch.length >= 12) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _submitBigBranch() {
    if (bigBranch.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need exactly 12 items to complete your Big Branch'),
        ),
      );
      return;
    }

    final gameState = context.read<GameState>();

    print('Submitting Big Branch...');
    print('Tree ID: ${widget.tree.id}');
    print('User ID: ${gameState.currentUser!.id}');
    print('Partner ID: ${gameState.partner!.id}');
    print('Items: ${bigBranch.length}');

    // Save to local tree
    widget.tree.myBigBranch = bigBranch;

    // Sync to shared storage
    GameSyncService.storeBigBranch(
      widget.tree.id,
      gameState.currentUser!.id,
      bigBranch,
    );

    print('Big Branch stored successfully!');

    setState(() {
      isSubmitted = true;
      isWaitingForPartner = true;
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Big Branch locked in! Waiting for partner...'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 3),
      ),
    );

    // Check immediately if partner is done
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkPartnerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Big Branch'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pointsRemaining pts left',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: isSubmitted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom,
                      size: 80,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Your Big Branch is Locked In!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Waiting for ${gameState.partner?.displayName ?? "your partner"} to complete...',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Checking every 2 seconds...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Debug info
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text('Tree ID: ${widget.tree.id}',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        ),
                        Text('Your ID: ${gameState.currentUser?.id ?? "unknown"}',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        ),
                        Text('Partner ID: ${gameState.partner?.id ?? "unknown"}',
                          style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: bigBranch.length / 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              bigBranch.length == 12 ? AppTheme.primaryGreen : Colors.orange,
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bigBranch.length + (bigBranch.length < 12 ? 1 : 0),
              itemBuilder: (context, index) {
                // New item input
                if (index == bigBranch.length && bigBranch.length < 12) {
                  return Card(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item ${bigBranch.length + 1} of 12',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: itemController,
                                  focusNode: itemFocus,
                                  decoration: const InputDecoration(
                                    hintText: 'What do you want, need, or love?',
                                    border: OutlineInputBorder(),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => _addCurrentItem(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: pointsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Points',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addCurrentItem,
                                icon: const Icon(Icons.add_circle),
                                color: AppTheme.primaryGreen,
                                iconSize: 36,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Existing items
                final item = bigBranch[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(item.description),
                    trailing: SizedBox(
                      width: 60,
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: item.points.toString()),
                        onChanged: (value) {
                          final points = int.tryParse(value);
                          if (points != null) {
                            _updateItemPoints(index, points);
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom actions
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
                if (bigBranch.length < 12)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _fillFromPopular,
                      icon: const Icon(Icons.list),
                      label: Text('Fill from Popular (${12 - bigBranch.length} needed)'),
                    ),
                  ),
                if (bigBranch.length == 12)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: bigBranch.length == 12 ? _submitBigBranch : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bigBranch.length == 12
                          ? AppTheme.primaryGreen
                          : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        bigBranch.length == 12
                          ? 'Lock In Big Branch (${25 - pointsRemaining} points used)'
                          : 'Add ${12 - bigBranch.length} more item${bigBranch.length == 11 ? '' : 's'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}