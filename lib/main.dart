import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_app_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
      ],
      child: const WillingTreeApp(),
    ),
  );
}

class WillingTreeApp extends StatelessWidget {
  const WillingTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WillingTree',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer<GameState>(
        builder: (context, gameState, child) {
          if (!gameState.isAuthenticated) {
            return const WelcomeScreen();
          }
          return const MainAppScreen();
        },
      ),
    );
  }
}