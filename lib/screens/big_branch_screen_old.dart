import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
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
  final TextEditingController newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing big branch if updating
    if (widget.tree.myBigBranch.isNotEmpty) {
      bigBranch.addAll(widget.tree.myBigBranch);
      calculateRemainingPoints();
    }
  }

  void calculateRemainingPoints() {
    int used = bigBranch.fold(0, (sum, item) => sum + item.points);
    setState(() {
      pointsRemaining = 25 - used;
    });
  }

  void addItem() {
    if (newItemController.text.isEmpty || bigBranch.length >= 12) return;

    setState(() {
      bigBranch.add(WantItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: newItemController.text,
        points: 1,
      ));
      pointsRemaining -= 1;
      newItemController.clear();
    });
  }

  void updatePoints(int index, int newPoints) {
    if (newPoints < 1 || newPoints > 25) return;

    int currentPoints = bigBranch[index].points;
    int difference = newPoints - currentPoints;

    if (pointsRemaining - difference < 0) return;

    setState(() {
      bigBranch[index].points = newPoints;
      calculateRemainingPoints();
    });
  }

  void submitBigBranch() {
    if (bigBranch.length < 12 || pointsRemaining > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need exactly 12 items and must use all 25 points'),
        ),
      );
      return;
    }

    // Save to tree
    widget.tree.myBigBranch = bigBranch;

    // Check if partner has completed their big branch
    if (widget.tree.partnerBigBranch.isNotEmpty) {
      // Both complete - start timer!
      context.read<GameState>().startTimer();

      // Show timer started message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('⏰ The Timer Has Started!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${widget.tree.partnerName} just completed their Big Branch'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      '144 hours countdown begins NOW',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Time to grow Little Branches!'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LittleBranchScreen(tree: widget.tree),
                  ),
                );
              },
              child: Text('See ${widget.tree.partnerName}\'s Big Branch'),
            ),
          ],
        ),
      );
    } else {
      // Waiting for partner
      widget.tree.phase = GamePhase.waitingForPartner;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isUpdating = widget.tree.phase == GamePhase.updating;

    return Scaffold(
      appBar: AppBar(
        title: Text('You & ${widget.tree.partnerName} - Big Branch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
                  'What would you want, need, or love from ${widget.tree.partnerName}?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Build your Big Branch (${bigBranch.length} of 12)',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Points left: $pointsRemaining of 25',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: bigBranch.length + 1,
              itemBuilder: (context, index) {
                if (index == bigBranch.length) {
                  // Add new item field
                  if (bigBranch.length >= 12) {
                    return const SizedBox.shrink();
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newItemController,
                          decoration: const InputDecoration(
                            hintText: 'Add to your Big Branch...',
                          ),
                          onSubmitted: (_) => addItem(),
                        ),
                      ),
                      IconButton(
                        onPressed: addItem,
                        icon: const Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                      ),
                    ],
                  );
                }

                final item = bigBranch[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.primaryGreen),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          controller: TextEditingController(text: item.points.toString()),
                          onChanged: (value) {
                            int? newPoints = int.tryParse(value);
                            if (newPoints != null) {
                              updatePoints(index, newPoints);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (bigBranch.length < 12)
            Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () {
                  // Show popular suggestions
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text('+ Fill from Popular List (${12 - bigBranch.length} needed)'),
              ),
            ),
          if (bigBranch.length == 12 && pointsRemaining == 0)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: submitBigBranch,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(isUpdating ? 'Update Big Branch' : 'Lock In Big Branch'),
              ),
            ),
        ],
      ),
    );
  }
}