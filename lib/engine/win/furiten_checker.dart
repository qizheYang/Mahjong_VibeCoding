import '../state/player_state.dart';
import 'tenpai_detector.dart';

/// Checks furiten conditions for a player.
class FuritenChecker {
  FuritenChecker._();

  /// Permanent furiten: any of the player's waiting tiles exists in their
  /// own discard pool.
  static bool isPermanentFuriten(PlayerState player, int meldCount) {
    final waits = TenpaiDetector.findWaits(
      List.from(player.kindCounts),
      meldCount,
    );
    if (waits.isEmpty) return false;
    return player.discards.any((tile) => waits.contains(tile.kind));
  }

  /// Temporary furiten: player has declined a ron opportunity since their
  /// last turn. Cleared when it becomes the player's turn again.
  static bool isTemporaryFuriten(PlayerState player) {
    return player.hasDeclinedRon;
  }

  /// Riichi furiten: player is in riichi and has declined any ron opportunity.
  /// This persists for the rest of the round once triggered.
  static bool isRiichiFuriten(PlayerState player) {
    return player.isRiichi && player.hasDeclinedRon;
  }

  /// Check if a player is in any form of furiten.
  static bool isFuriten(PlayerState player, int meldCount) {
    if (isTemporaryFuriten(player)) return true;
    if (isRiichiFuriten(player)) return true;
    if (isPermanentFuriten(player, meldCount)) return true;
    return false;
  }
}
