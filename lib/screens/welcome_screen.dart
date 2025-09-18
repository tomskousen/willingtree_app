import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/web_pairing_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'name_setup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    _checkForInviteCode();
  }

  void _checkForInviteCode() {
    final code = WebPairingService.getInviteCodeFromUrl();
    if (code != null) {
      setState(() {
        _inviteCode = code;
      });
      // Show special UI for invite links
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInviteDialog();
      });
    }
  }

  void _showInviteDialog() {
    if (_inviteCode == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('You\'ve been invited!'),
        content: const Text(
          'Someone has invited you to connect on WillingTree. Sign up or log in to accept the invitation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SignUpScreen(inviteCode: _inviteCode),
                ),
              );
            },
            child: const Text('Sign Up'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(inviteCode: _inviteCode),
                ),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Center(
                  child: Text(
                    '🌳',
                    style: TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome to WillingTree',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Evolve core relationships with the trust/safety that emerges when practicing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Want • Willing • Won\'t',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignUpScreen(inviteCode: _inviteCode)),
                    );
                  },
                  child: const Text('Sign Up Free'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen(inviteCode: _inviteCode)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryGreen),
                  ),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Free game • Premium insights available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  final String? inviteCode;
  const SignUpScreen({super.key, this.inviteCode});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gameState = context.read<GameState>();
      await gameState.loginWithPhone(phone);
      if (mounted) {
        // Pass invite code to name setup if present
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => NameSetupScreen(inviteCode: widget.inviteCode)),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
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
              'Create Your Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                hintText: 'Phone Number',
                prefixText: '+1 ',
              ),
              keyboardType: TextInputType.phone,
              autofocus: true,
              onSubmitted: (_) => _handleSignUp(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}