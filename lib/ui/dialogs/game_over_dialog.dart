import 'package:flutter/material.dart';
import '../../engine/state/game_state.dart';

/// Dialog showing final game results and standings.
class GameOverDialog extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const GameOverDialog({
    super.key,
    required this.gameState,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Sort players by score (descending)
    final rankings = List.generate(4, (i) => i);
    rankings.sort((a, b) => gameState.scores[b].compareTo(gameState.scores[a]));

    return Dialog(
      backgroundColor: const Color(0xFF1B3A1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Rankings
            ...List.generate(4, (rank) {
              final pi = rankings[rank];
              final score = gameState.scores[pi];
              final isHuman = pi == 0;
              final isWinner = rank == 0;
              final placement = ['1st', '2nd', '3rd', '4th'][rank];
              final label = isHuman ? 'You' : 'AI $pi';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        placement,
                        style: TextStyle(
                          color: isWinner ? Colors.amber : Colors.white70,
                          fontSize: 16,
                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 60,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isHuman ? Colors.amber : Colors.white,
                          fontSize: 16,
                          fontWeight: isHuman ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$score',
                      style: TextStyle(
                        color: score >= 0 ? Colors.white : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Play Again'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onMainMenu,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  child: const Text('Main Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
