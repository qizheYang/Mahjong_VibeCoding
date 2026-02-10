import '../state/action.dart';
import '../state/player_state.dart';
import '../state/round_state.dart';
import '../win/shanten_calculator.dart';
import 'ai_player.dart';
import 'ai_utils.dart';

/// A functional AI that uses shanten reduction for discards
/// and simple heuristics for call decisions.
class BasicAi implements AiPlayer {
  @override
  PlayerAction decideAction(
    RoundState state,
    int playerIndex,
    List<PlayerAction> legalActions,
  ) {
    if (legalActions.isEmpty) return SkipAction(playerIndex);

    // Priority 1: Always declare tsumo
    final tsumo = legalActions.whereType<TsumoAction>().firstOrNull;
    if (tsumo != null) return tsumo;

    // Priority 2: Always declare ron
    final ron = legalActions.whereType<RonAction>().firstOrNull;
    if (ron != null) return ron;

    // Priority 3: If we have to discard (it's our turn)
    final discards = legalActions.whereType<DiscardAction>().toList();
    if (discards.isNotEmpty) {
      return _selectDiscard(state, playerIndex, discards, legalActions);
    }

    // Priority 4: Evaluate calls (pon/chi/kan)
    return _evaluateCall(state, playerIndex, legalActions);
  }

  PlayerAction _selectDiscard(
    RoundState state,
    int playerIndex,
    List<DiscardAction> discards,
    List<PlayerAction> allActions,
  ) {
    final player = state.players[playerIndex];

    // Check for riichi opportunity
    final riichiDiscards = discards.where((d) => d.declareRiichi).toList();
    if (riichiDiscards.isNotEmpty && player.isMenzen) {
      // AI always declares riichi when possible
      return _bestRiichiDiscard(state, player, riichiDiscards);
    }

    // Check for closed kan opportunity
    final closedKans = allActions.whereType<ClosedKanAction>().toList();
    if (closedKans.isNotEmpty) {
      return closedKans.first;
    }

    // Check for added kan opportunity
    final addedKans = allActions.whereType<AddedKanAction>().toList();
    if (addedKans.isNotEmpty) {
      return addedKans.first;
    }

    // Select best discard using shanten reduction
    return _bestDiscard(state, player, discards);
  }

  DiscardAction _bestDiscard(
    RoundState state,
    PlayerState player,
    List<DiscardAction> discards,
  ) {
    final counts = player.kindCounts;

    DiscardAction? bestAction;
    int bestShanten = 99;
    double bestPriority = -999;

    for (final action in discards) {
      if (action.declareRiichi) continue; // handled separately

      final tile = action.tile;
      // Calculate shanten after discarding this tile
      final newCounts = List<int>.from(counts);
      newCounts[tile.kind]--;
      final newShanten = ShantenCalculator.calculate(newCounts, player.melds.length);
      final priority = AiUtils.discardPriority(player, tile, state);

      if (newShanten < bestShanten ||
          (newShanten == bestShanten && priority > bestPriority)) {
        bestShanten = newShanten;
        bestPriority = priority;
        bestAction = action;
      }
    }

    return bestAction ?? discards.first;
  }

  DiscardAction _bestRiichiDiscard(
    RoundState state,
    PlayerState player,
    List<DiscardAction> riichiDiscards,
  ) {
    // Among riichi discards, pick the safest one
    DiscardAction? best;
    double bestPriority = -999;

    for (final action in riichiDiscards) {
      final priority = AiUtils.discardPriority(player, action.tile, state);
      if (priority > bestPriority) {
        bestPriority = priority;
        best = action;
      }
    }

    return best ?? riichiDiscards.first;
  }

  PlayerAction _evaluateCall(
    RoundState state,
    int playerIndex,
    List<PlayerAction> legalActions,
  ) {
    final player = state.players[playerIndex];
    final counts = player.kindCounts;
    final currentShanten = ShantenCalculator.calculate(counts, player.melds.length);

    // Check pon
    final pons = legalActions.whereType<PonAction>().toList();
    for (final pon in pons) {
      // Simulate the pon: remove 2 tiles from hand, add meld
      final newCounts = List<int>.from(counts);
      newCounts[pon.calledTile.kind] -= 2;
      final newShanten = ShantenCalculator.calculate(newCounts, player.melds.length + 1);
      if (newShanten < currentShanten) return pon;
    }

    // Check chi
    final chis = legalActions.whereType<ChiAction>().toList();
    for (final chi in chis) {
      final newCounts = List<int>.from(counts);
      newCounts[chi.handTile1.kind]--;
      newCounts[chi.handTile2.kind]--;
      final newShanten = ShantenCalculator.calculate(newCounts, player.melds.length + 1);
      if (newShanten < currentShanten) return chi;
    }

    // Default: skip
    final skip = legalActions.whereType<SkipAction>().firstOrNull;
    return skip ?? legalActions.last;
  }
}
