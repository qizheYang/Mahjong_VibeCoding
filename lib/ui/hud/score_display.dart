import 'package:flutter/material.dart';
import '../../engine/state/game_state.dart';

/// Displays all four players' scores in a compact format.
class ScoreDisplay extends StatelessWidget {
  final GameState gameState;

  const ScoreDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final round = gameState.currentRound;
    final windNames = ['東', '南', '西', '北'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final seatWind = round != null ? round.players[i].seatWind : i;
          final wind = windNames[seatWind];
          final score = gameState.scores[i];
          final isDealer = round != null && i == round.dealerIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$wind ',
                  style: TextStyle(
                    color: i == 0 ? Colors.amber : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    color: i == 0 ? Colors.amber : Colors.white,
                    fontSize: 13,
                  ),
                ),
                if (isDealer)
                  const Text(
                    ' D',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
