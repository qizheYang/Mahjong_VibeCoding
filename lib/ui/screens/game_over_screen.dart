import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_controller_provider.dart';
import '../dialogs/game_over_dialog.dart';
import 'game_screen.dart';
import 'title_screen.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);

    return Scaffold(
      body: Center(
        child: GameOverDialog(
          gameState: gameState,
          onPlayAgain: () {
            ref.read(gameControllerProvider.notifier).startGame(gameState.config);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
          },
          onMainMenu: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TitleScreen()),
            );
          },
        ),
      ),
    );
  }
}
