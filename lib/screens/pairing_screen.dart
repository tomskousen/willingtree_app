import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'main_app_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeController = TextEditingController();
  String? _myCode;
  String? _inviteLink;
  bool _isLoading = false;
  Timer? _pairingCheckTimer;

  @override
  void initState() {
    super.initState();
    // Delay generation to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateCode();
      _startPairingCheck();
    });
  }

  void _generateCode() {
    final gameState = context.read<GameState>();
    final code = gameState.generatePairingCode();
    final link = gameState.getInviteLink();
    if (mounted) {
      setState(() {
        _myCode = code;
        _inviteLink = link;
      });
    }
  }

  void _startPairingCheck() {
    // Check every 2 seconds if someone has paired with us
    _pairingCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final gameState = context.read<GameState>();
      final paired = await gameState.checkForPairing();

      if (paired && mounted) {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Partner connected! Starting game...'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        // Start new game after detecting pairing
        _startNewGameAfterPairing(gameState);
      }
    });
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pairing code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gameState = context.read<GameState>();
      final success = await gameState.pairWithCode(code);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully paired! Starting game...'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );

        // Start a new game immediately after pairing
        _startNewGameAfterPairing(gameState);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid pairing code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startNewGameAfterPairing(GameState gameState) {
    if (gameState.partner == null) return;

    // Create a deterministic tree ID
    final userId1 = gameState.currentUser!.id;
    final userId2 = gameState.partner!.id;
    final sortedIds = [userId1, userId2]..sort();
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final treeId = 'tree_${sortedIds[0]}_${sortedIds[1]}_$dateStr';

    final newTree = WillingTree(
      id: treeId,
      partnerId: gameState.partner!.id,
      partnerName: gameState.partner!.displayName ?? gameState.partner!.phoneNumber,
    );
    gameState.activeTree = newTree;
    gameState.trees.add(newTree);

    // Navigate directly to Big Branch screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainAppScreen(
          initialIndex: 1, // Tree tab
          activeTree: newTree,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair with Partner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pair with Your WillingTree Partner',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Share your code with your partner or enter theirs',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 40),

            // My pairing code
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Pairing Code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _myCode ?? '------',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_myCode != null) {
                            Clipboard.setData(ClipboardData(text: _myCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Share this code with your partner',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                  if (_inviteLink != null) ...[
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Or share this link:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inviteLink!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _inviteLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.link, color: AppTheme.primaryGreen, size: 20),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: AppTheme.textLight)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 30),

            // Enter partner's code
            const Text(
              'Enter Partner\'s Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Enter 6-digit code',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinWithCode,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Join with Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pairingCheckTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }
}