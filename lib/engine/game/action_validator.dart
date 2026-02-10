import '../tile/tile.dart';
import '../tile/tile_constants.dart';
import '../state/action.dart';
import '../state/meld.dart';
import '../state/player_state.dart';
import '../state/round_state.dart';
import '../win/win_detector.dart';
import '../win/tenpai_detector.dart';
import '../win/furiten_checker.dart';

/// Validates and enumerates legal actions for the current game state.
class ActionValidator {
  ActionValidator._();

  /// Get all legal actions for a player in the current state.
  static List<PlayerAction> getAvailableActions(RoundState state, int playerIndex) {
    final player = state.players[playerIndex];
    final actions = <PlayerAction>[];

    if (state.phase == RoundPhase.playerTurn && state.currentTurn == playerIndex) {
      // It's this player's turn — they have drawn a tile
      actions.addAll(_getTurnActions(state, player));
    } else if (state.phase == RoundPhase.awaitingCalls &&
        state.lastDiscardedBy != playerIndex) {
      // Another player discarded — check for calls
      actions.addAll(_getCallActions(state, player));
    }

    return actions;
  }

  /// Actions available during a player's turn (after drawing).
  static List<PlayerAction> _getTurnActions(RoundState state, PlayerState player) {
    final actions = <PlayerAction>[];
    final pi = player.seatIndex;

    // Check for tsumo (self-draw win)
    if (_canTsumo(state, player)) {
      actions.add(TsumoAction(pi));
    }

    // Check for closed kan (ankan)
    if (!player.isRiichi) {
      actions.addAll(_getClosedKanActions(state, player));
    } else {
      // In riichi, can only declare closed kan if it doesn't change the wait
      actions.addAll(_getRiichiClosedKanActions(state, player));
    }

    // Check for added kan (shouminkan)
    if (!player.isRiichi) {
      actions.addAll(_getAddedKanActions(state, player));
    }

    // Check for riichi declaration
    if (_canDeclareRiichi(state, player)) {
      final riichiDiscards = _getRiichiDiscards(state, player);
      for (final tile in riichiDiscards) {
        actions.add(DiscardAction(pi, tile, declareRiichi: true));
      }
    }

    // Check for kyuushu kyuuhai (9 terminals abort)
    if (_canAbortKyuushu(state, player)) {
      actions.add(AbortAction(pi, AbortReason.kyuushuKyuuhai));
    }

    // Regular discard (must discard if in riichi — only the drawn tile)
    if (player.isRiichi) {
      if (player.justDrew != null) {
        actions.add(DiscardAction(pi, player.justDrew!));
      }
    } else {
      for (final tile in player.hand) {
        actions.add(DiscardAction(pi, tile));
      }
    }

    return actions;
  }

  /// Call actions available when another player discards.
  static List<PlayerAction> _getCallActions(RoundState state, PlayerState player) {
    final actions = <PlayerAction>[];
    final pi = player.seatIndex;
    final discardedTile = state.lastDiscardedTile!;
    final discardedBy = state.lastDiscardedBy!;

    // Ron
    if (_canRon(state, player)) {
      actions.add(RonAction(pi));
    }

    // Can't make other calls if in riichi
    if (player.isRiichi) {
      if (actions.isNotEmpty) {
        actions.add(SkipAction(pi));
      }
      return actions;
    }

    // Pon
    final ponActions = _getPonActions(player, discardedTile, discardedBy);
    actions.addAll(ponActions);

    // Open kan (daiminkan)
    final openKanActions = _getOpenKanActions(state, player, discardedTile, discardedBy);
    actions.addAll(openKanActions);

    // Chi (only from the player to the left)
    if ((discardedBy + 1) % 4 == pi) {
      final chiActions = _getChiActions(player, discardedTile);
      actions.addAll(chiActions);
    }

    if (actions.isNotEmpty) {
      actions.add(SkipAction(pi));
    }

    return actions;
  }

  static bool _canTsumo(RoundState state, PlayerState player) {
    final counts = player.kindCounts;
    return WinDetector.isWinning(counts, player.melds.length);
  }

  static bool _canRon(RoundState state, PlayerState player) {
    if (state.lastDiscardedTile == null) return false;

    // Check furiten
    if (FuritenChecker.isFuriten(player, player.melds.length)) return false;

    // Add the discarded tile to hand and check for win
    final counts = player.kindCounts;
    final discardKind = state.lastDiscardedTile!.kind;
    counts[discardKind]++;
    final isWin = WinDetector.isWinning(counts, player.melds.length);
    counts[discardKind]--;
    return isWin;
  }

  static List<PlayerAction> _getClosedKanActions(RoundState state, PlayerState player) {
    final actions = <PlayerAction>[];
    if (state.kanCount >= 4) return actions; // max 4 kans per round

    final counts = player.kindCounts;
    for (int k = 0; k < 34; k++) {
      if (counts[k] == 4) {
        actions.add(ClosedKanAction(player.seatIndex, k));
      }
    }
    return actions;
  }

  static List<PlayerAction> _getRiichiClosedKanActions(RoundState state, PlayerState player) {
    // In riichi, can only closed kan if:
    // 1. Have 4 of a kind
    // 2. The kan doesn't change the waiting tiles
    final actions = <PlayerAction>[];
    if (state.kanCount >= 4) return actions;

    final counts = player.kindCounts;
    final currentWaits = TenpaiDetector.findWaits(List.from(counts), player.melds.length);

    for (int k = 0; k < 34; k++) {
      if (counts[k] == 4) {
        // Simulate the kan: remove 4, add one meld
        final newCounts = List<int>.from(counts);
        newCounts[k] = 0;
        final newWaits = TenpaiDetector.findWaits(newCounts, player.melds.length + 1);
        if (_setsEqual(currentWaits, newWaits)) {
          actions.add(ClosedKanAction(player.seatIndex, k));
        }
      }
    }
    return actions;
  }

  static List<PlayerAction> _getAddedKanActions(RoundState state, PlayerState player) {
    final actions = <PlayerAction>[];
    if (state.kanCount >= 4) return actions;

    for (int i = 0; i < player.melds.length; i++) {
      final meld = player.melds[i];
      if (meld.type != MeldType.pon) continue;
      final meldKind = meld.tiles.first.kind;
      // Check if player has the 4th tile in hand
      final matchingTile = player.hand.where((t) => t.kind == meldKind).firstOrNull;
      if (matchingTile != null) {
        actions.add(AddedKanAction(player.seatIndex, addedTile: matchingTile, meldIndex: i));
      }
    }
    return actions;
  }

  static bool _canDeclareRiichi(RoundState state, PlayerState player) {
    if (player.isRiichi) return false;
    if (!player.isMenzen) return false;
    if (state.wall.remaining < 4) return false; // need at least 4 tiles for others to draw
    // Need to be tenpai after discarding some tile
    return _getRiichiDiscards(state, player).isNotEmpty;
  }

  static List<Tile> _getRiichiDiscards(RoundState state, PlayerState player) {
    final validDiscards = <Tile>[];
    final seen = <int>{}; // avoid duplicate kinds
    for (final tile in player.hand) {
      if (!seen.add(tile.kind)) continue;
      // Remove this tile and check tenpai
      final counts = player.kindCounts;
      counts[tile.kind]--;
      if (TenpaiDetector.isTenpai(counts, player.melds.length)) {
        validDiscards.add(tile);
      }
      counts[tile.kind]++;
    }
    return validDiscards;
  }

  static bool _canAbortKyuushu(RoundState state, PlayerState player) {
    // Can only abort on player's very first turn, before any calls
    if (!state.isFirstGoAround) return false;
    if (player.discards.isNotEmpty) return false;

    // Count distinct terminal/honor kinds in hand
    final kinds = <int>{};
    for (final tile in player.hand) {
      if (TileConstants.isTerminalOrHonor(tile.kind)) {
        kinds.add(tile.kind);
      }
    }
    return kinds.length >= 9;
  }

  static List<PlayerAction> _getPonActions(
    PlayerState player, Tile discardedTile, int discardedBy,
  ) {
    final actions = <PlayerAction>[];
    final matching = player.hand.where((t) => t.kind == discardedTile.kind).toList();
    if (matching.length < 2) return actions;

    // Use the first two matching tiles
    actions.add(PonAction(player.seatIndex,
      calledTile: discardedTile,
      handTile1: matching[0],
      handTile2: matching[1],
    ));
    return actions;
  }

  static List<PlayerAction> _getOpenKanActions(
    RoundState state, PlayerState player, Tile discardedTile, int discardedBy,
  ) {
    final actions = <PlayerAction>[];
    if (state.kanCount >= 4) return actions;

    final matching = player.hand.where((t) => t.kind == discardedTile.kind).toList();
    if (matching.length < 3) return actions;

    actions.add(OpenKanAction(player.seatIndex,
      calledTile: discardedTile,
      handTiles: matching.sublist(0, 3),
    ));
    return actions;
  }

  static List<PlayerAction> _getChiActions(PlayerState player, Tile discardedTile) {
    final actions = <PlayerAction>[];
    final kind = discardedTile.kind;

    if (!TileConstants.isSuited(kind)) return actions;

    final num = TileConstants.numberOf(kind);
    final suit = TileConstants.suitOf(kind);

    // Three possible sequences containing this tile:
    // [kind-2, kind-1, kind], [kind-1, kind, kind+1], [kind, kind+1, kind+2]
    final combos = <List<int>>[];
    if (num >= 3) combos.add([kind - 2, kind - 1]);
    if (num >= 2 && num <= 8) combos.add([kind - 1, kind + 1]);
    if (num <= 7) combos.add([kind + 1, kind + 2]);

    for (final combo in combos) {
      // Verify both tiles are same suit
      if (combo.any((k) => k < 0 || k >= 27 || TileConstants.suitOf(k) != suit)) continue;

      final tile1 = player.hand.where((t) => t.kind == combo[0]).firstOrNull;
      final tile2 = player.hand.where((t) => t.kind == combo[1]).firstOrNull;
      if (tile1 != null && tile2 != null) {
        actions.add(ChiAction(player.seatIndex,
          calledTile: discardedTile,
          handTile1: tile1,
          handTile2: tile2,
        ));
      }
    }
    return actions;
  }

  static bool _setsEqual<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.every((e) => b.contains(e));
  }
}
