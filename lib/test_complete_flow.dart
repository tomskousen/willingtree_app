import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'models/game_state.dart';
import 'models/user_model.dart';
import 'services/game_sync_service.dart';
import 'theme/app_theme.dart';

class TestCompleteFlow extends StatefulWidget {
  const TestCompleteFlow({super.key});

  @override
  State<TestCompleteFlow> createState() => _TestCompleteFlowState();
}

class _TestCompleteFlowState extends State<TestCompleteFlow> {
  List<String> logs = [];
  bool isRunning = false;
  String currentStep = '';

  void log(String message) {
    setState(() {
      logs.add('[${DateTime.now().toLocal()}] $message');
    });
    print(message);
  }

  Future<void> clearAllData() async {
    log('Clearing all test data...');
    // Clear relevant localStorage data
    GameSyncService.clearTreeData('test_tree');
    log('Data cleared successfully');
  }

  Future<void> runCompleteTest() async {
    setState(() {
      isRunning = true;
      logs.clear();
    });

    try {
      // Clear previous test data
      await clearAllData();

      // Step 1: Create two users
      currentStep = 'Creating users...';
      log('Step 1: Creating users...');

      final user1 = UserModel.create('555-1111');
      user1.displayName = 'Alice';

      final user2 = UserModel.create('555-2222');
      user2.displayName = 'Bob';

      log('Created User 1: ${user1.displayName} (${user1.id})');
      log('Created User 2: ${user2.displayName} (${user2.id})');

      // Step 2: Pair users
      currentStep = 'Pairing users...';
      log('\nStep 2: Pairing users...');

      user1.partnerId = user2.id;
      user2.partnerId = user1.id;

      log('Users paired successfully');

      // Step 3: Create a new tree
      currentStep = 'Creating WillingTree...';
      log('\nStep 3: Creating WillingTree...');

      final tree = WillingTree(
        id: 'test_tree',
        partnerId: user2.id,
        partnerName: user2.displayName!,
      );

      log('Tree created with ID: ${tree.id}');

      // Step 4: User 1 creates Big Branch
      currentStep = 'User 1 creating Big Branch...';
      log('\nStep 4: User 1 creating Big Branch...');

      final user1BigBranch = _createTestBigBranch('User1');
      GameSyncService.storeBigBranch(tree.id, user1.id, user1BigBranch);

      log('User 1 Big Branch created:');
      log('  - Items: ${user1BigBranch.length}');
      log('  - Total points: ${user1BigBranch.fold(0, (sum, item) => sum + item.points)}');

      // Step 5: User 2 creates Big Branch
      currentStep = 'User 2 creating Big Branch...';
      log('\nStep 5: User 2 creating Big Branch...');

      final user2BigBranch = _createTestBigBranch('User2');
      GameSyncService.storeBigBranch(tree.id, user2.id, user2BigBranch);

      log('User 2 Big Branch created:');
      log('  - Items: ${user2BigBranch.length}');
      log('  - Total points: ${user2BigBranch.fold(0, (sum, item) => sum + item.points)}');

      // Step 6: Check if both complete
      currentStep = 'Checking completion status...';
      log('\nStep 6: Checking if both users completed...');

      final bothComplete = GameSyncService.areBothBigBranchesComplete(
        tree.id,
        user1.id,
        user2.id,
      );

      log('Both users complete: $bothComplete');

      if (bothComplete) {
        // Step 7: Start timer
        currentStep = 'Starting timer...';
        log('\nStep 7: Starting timer...');

        GameSyncService.startTimer(tree.id);
        log('Timer started successfully');

        // Step 8: Load partner's Big Branch for Little Branch selection
        currentStep = 'Loading partner data...';
        log('\nStep 8: Loading partner data for Little Branch...');

        final user1SeeUser2 = GameSyncService.getPartnerBigBranch(tree.id, user2.id);
        final user2SeeUser1 = GameSyncService.getPartnerBigBranch(tree.id, user1.id);

        log('User 1 can see ${user1SeeUser2?.length ?? 0} items from User 2');
        log('User 2 can see ${user2SeeUser1?.length ?? 0} items from User 1');

        // Step 9: User 1 creates Little Branch
        if (user1SeeUser2 != null && user1SeeUser2.isNotEmpty) {
          currentStep = 'User 1 creating Little Branch...';
          log('\nStep 9: User 1 creating Little Branch...');

          final random = Random();
          final randomItem = user1SeeUser2[random.nextInt(user1SeeUser2.length)];

          final remaining = user1SeeUser2.where((item) => item.id != randomItem.id).toList();
          remaining.shuffle();

          final selectedItems = remaining.take(2).toList();

          final user1LittleBranch = [randomItem, ...selectedItems];
          GameSyncService.storeLittleBranch(tree.id, user1.id, user1LittleBranch);

          log('User 1 Little Branch created:');
          log('  - Random item: ${randomItem.description}');
          log('  - Selected items: ${selectedItems.map((i) => i.description).join(', ')}');
        }

        // Step 10: User 2 creates Little Branch
        if (user2SeeUser1 != null && user2SeeUser1.isNotEmpty) {
          currentStep = 'User 2 creating Little Branch...';
          log('\nStep 10: User 2 creating Little Branch...');

          final random = Random();
          final randomItem = user2SeeUser1[random.nextInt(user2SeeUser1.length)];

          final remaining = user2SeeUser1.where((item) => item.id != randomItem.id).toList();
          remaining.shuffle();

          final selectedItems = remaining.take(2).toList();

          final user2LittleBranch = [randomItem, ...selectedItems];
          GameSyncService.storeLittleBranch(tree.id, user2.id, user2LittleBranch);

          log('User 2 Little Branch created:');
          log('  - Random item: ${randomItem.description}');
          log('  - Selected items: ${selectedItems.map((i) => i.description).join(', ')}');
        }

        currentStep = '✅ Test Complete!';
        log('\n✅ TEST COMPLETE - All steps executed successfully!');
        log('The app should now transition through all screens automatically.');
      } else {
        currentStep = '❌ Test Failed';
        log('\n❌ TEST FAILED - Both users did not complete Big Branch');
      }

    } catch (e) {
      currentStep = '❌ Error occurred';
      log('\n❌ ERROR: $e');
    } finally {
      setState(() {
        isRunning = false;
      });
    }
  }

  List<WantItem> _createTestBigBranch(String prefix) {
    final suggestions = GameSyncService.getPopularSuggestions();
    final items = <WantItem>[];

    int pointsRemaining = 25;
    for (int i = 0; i < 12; i++) {
      final isLast = i == 11;
      final points = isLast ? pointsRemaining : min(pointsRemaining, Random().nextInt(3) + 1);

      items.add(WantItem(
        id: '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$i',
        description: suggestions[i % suggestions.length],
        points: points,
      ));

      pointsRemaining -= points;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Flow Test'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryGreen.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  currentStep.isEmpty ? 'Ready to test' : currentStep,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isRunning ? null : runCompleteTest,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Run Complete Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: isRunning ? null : clearAllData,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    logs[index],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}