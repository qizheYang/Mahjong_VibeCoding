import 'package:flutter/material.dart';
import '../../engine/state/game_state.dart';

/// Displays the current round wind, number, honba, and riichi sticks.
class RoundIndicator extends StatelessWidget {
  final GameState gameState;

  const RoundIndicator({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final windNames = ['東', '南', '西', '北'];
    final roundWind = windNames[gameState.roundWind];
    final roundNum = gameState.roundNumber + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$roundWind$roundNum局',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (gameState.honbaCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${gameState.honbaCount}本場',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (gameState.riichiSticksOnTable > 0) ...[
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'x${gameState.riichiSticksOnTable}',
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
