import '../state/game_state.dart';
import '../state/round_state.dart';
import '../win/tenpai_detector.dart';

/// Manages turn order, dealer rotation, and round advancement.
class TurnManager {
  TurnManager._();

  /// Get the next player index in turn order.
  static int nextPlayer(int current) => (current + 1) % 4;

  /// Determine if the dealer continues (renchan) or rotates.
  /// Returns the updated GameState for the next round.
  static GameState advanceRound(
    GameState gameState,
    RoundEndReason endReason, {
    required int? winnerIndex,
    required List<int> scoreChanges,
    required int riichiSticksCollected,
  }) {
    final currentDealer = gameState.dealerIndex;
    final dealerWon = winnerIndex == currentDealer;
    final bool dealerTenpai;

    if (endReason == RoundEndReason.exhaustiveDraw) {
      // Check if dealer is tenpai
      final round = gameState.currentRound!;
      final dealerState = round.players[currentDealer];
      dealerTenpai = TenpaiDetector.isTenpai(
        List.from(dealerState.kindCounts),
        dealerState.melds.length,
      );
    } else {
      dealerTenpai = false;
    }

    // Apply score changes
    final newScores = List<int>.from(gameState.scores);
    for (int i = 0; i < 4; i++) {
      newScores[i] += scoreChanges[i];
    }

    // Determine next round
    bool renchan = false;
    if (dealerWon) {
      renchan = true;
    } else if (endReason == RoundEndReason.exhaustiveDraw && dealerTenpai) {
      renchan = true;
    } else if (endReason == RoundEndReason.abortiveDraw) {
      renchan = true;
    }

    int newHonba;
    if (renchan) {
      newHonba = gameState.honbaCount + 1;
    } else if (endReason == RoundEndReason.exhaustiveDraw) {
      newHonba = gameState.honbaCount + 1;
    } else {
      newHonba = 0;
    }

    // Advance dealer if not renchan
    int newDealer = currentDealer;
    int newRoundWind = gameState.roundWind;
    int newRoundNumber = gameState.roundNumber;

    if (!renchan) {
      newDealer = (currentDealer + 1) % 4;
      newRoundNumber = gameState.roundNumber + 1;
      if (newRoundNumber >= 4) {
        newRoundNumber = 0;
        newRoundWind++;
      }
    }

    // Collect riichi sticks
    int remainingRiichiSticks = gameState.riichiSticksOnTable;
    if (winnerIndex != null) {
      remainingRiichiSticks = 0; // winner collects all
    }

    // Check game over
    bool isGameOver = false;
    if (newRoundWind >= gameState.config.totalWinds && !renchan) {
      isGameOver = true;
    }
    // Also game over if someone is below 0 (negative score)
    if (newScores.any((s) => s < 0)) {
      isGameOver = true;
    }
    // Overtime: if past normal round count but no one has target score
    if (newRoundWind >= gameState.config.totalWinds && renchan) {
      if (newScores.any((s) => s >= gameState.config.targetScore)) {
        isGameOver = true;
      }
    }

    return gameState.copyWith(
      scores: newScores,
      dealerIndex: newDealer,
      roundWind: newRoundWind,
      roundNumber: newRoundNumber,
      honbaCount: newHonba,
      riichiSticksOnTable: remainingRiichiSticks,
      isGameOver: isGameOver,
    );
  }
}
