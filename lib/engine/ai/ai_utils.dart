import '../tile/tile.dart';
import '../tile/tile_constants.dart';
import '../state/player_state.dart';
import '../state/round_state.dart';

/// Utility functions for AI decision making.
class AiUtils {
  AiUtils._();

  /// Count how many copies of a tile kind are visible (discards + own hand + melds).
  static int visibleCount(RoundState state, int playerIndex, int kind) {
    int count = 0;
    // Own hand
    for (final tile in state.players[playerIndex].hand) {
      if (tile.kind == kind) count++;
    }
    // All discards
    for (final player in state.players) {
      for (final tile in player.discards) {
        if (tile.kind == kind) count++;
      }
    }
    // All open melds
    for (final player in state.players) {
      for (final meld in player.melds) {
        for (final tile in meld.tiles) {
          if (tile.kind == kind) count++;
        }
      }
    }
    return count;
  }

  /// Get tiles that are safe to discard against a riichi player (genbutsu).
  static Set<int> getSafeTileKinds(RoundState state, int riichiPlayerIndex) {
    final safeKinds = <int>{};
    final riichiPlayer = state.players[riichiPlayerIndex];
    for (final tile in riichiPlayer.discards) {
      safeKinds.add(tile.kind);
    }
    return safeKinds;
  }

  /// Score a tile for discard priority (higher = safer to discard).
  static double discardPriority(
    PlayerState player, Tile tile, RoundState state,
  ) {
    double score = 0;
    final kind = tile.kind;

    // Isolated honors are good discards
    if (TileConstants.isHonor(kind)) {
      final count = player.hand.where((t) => t.kind == kind).length;
      if (count == 1) score += 10;
      if (count == 2) score -= 5; // pair, keep it
    }

    // Isolated terminals
    if (TileConstants.isTerminal(kind)) {
      final count = player.hand.where((t) => t.kind == kind).length;
      if (count == 1) {
        // Check if it has neighbors
        final hasNeighbor = player.hand.any((t) =>
            t.kind != kind &&
            TileConstants.isSuited(t.kind) &&
            TileConstants.suitOf(t.kind) == TileConstants.suitOf(kind) &&
            (t.kind - kind).abs() <= 2);
        if (!hasNeighbor) score += 8;
      }
    }

    // Tiles with more visible copies are less useful
    final visible = visibleCount(state, player.seatIndex, kind);
    score += visible * 2;

    // If any opponent declared riichi, prefer safe tiles
    for (int i = 0; i < 4; i++) {
      if (i == player.seatIndex) continue;
      if (state.players[i].isRiichi) {
        final safeKinds = getSafeTileKinds(state, i);
        if (safeKinds.contains(kind)) score += 20;
      }
    }

    return score;
  }
}
