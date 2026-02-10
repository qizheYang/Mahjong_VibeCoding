import 'dart:math';
import '../tile/tile.dart';
import '../state/action.dart';
import '../state/meld.dart';
import '../state/player_state.dart';
import '../state/round_state.dart';
import '../state/wall.dart';
import '../state/game_event.dart';
import '../win/tenpai_detector.dart';
import '../../utils/extensions.dart';

/// Pure functions for round lifecycle operations.
/// Each method takes state + action and returns new state + events.
class RoundFlow {
  RoundFlow._();

  /// Initialize a new round: create wall, deal tiles.
  static RoundState deal({
    required int roundWind,
    required int roundNumber,
    required int dealerIndex,
    Random? random,
  }) {
    final wall = Wall.shuffled(random: random);
    final players = <PlayerState>[];

    for (int i = 0; i < 4; i++) {
      final seatWind = (i - dealerIndex + 4) % 4;
      final hand = <Tile>[];
      for (int j = 0; j < 13; j++) {
        hand.add(wall.draw()!);
      }
      players.add(PlayerState(
        seatIndex: i,
        hand: hand,
        seatWind: seatWind,
      ));
    }

    // Dealer draws 14th tile
    final dealerDraw = wall.draw()!;
    final dealerHand = [...players[dealerIndex].hand, dealerDraw];
    players[dealerIndex] = players[dealerIndex].copyWith(
      hand: dealerHand,
      justDrew: () => dealerDraw,
    );

    return RoundState(
      wall: wall,
      players: players,
      currentTurn: dealerIndex,
      phase: RoundPhase.playerTurn,
      roundWind: roundWind,
      roundNumber: roundNumber,
      dealerIndex: dealerIndex,
      eventLog: [RoundStartEvent(roundWind, roundNumber, dealerIndex)],
    );
  }

  /// Draw a tile for the current player.
  static RoundState drawTile(RoundState state) {
    final pi = state.currentTurn;
    final tile = state.wall.draw();
    if (tile == null) {
      // Wall is empty — exhaustive draw
      return _handleExhaustiveDraw(state);
    }

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = newPlayers[pi].copyWith(
      hand: [...newPlayers[pi].hand, tile],
      justDrew: () => tile,
      hasDeclinedRon: false, // clear temporary furiten on own turn
    );

    return state.copyWith(
      players: newPlayers,
      phase: RoundPhase.playerTurn,
      turnCount: state.turnCount + 1,
      eventLog: [...state.eventLog, TileDrawnEvent(pi, tile)],
    );
  }

  /// Process a discard action.
  static RoundState discard(RoundState state, DiscardAction action) {
    final pi = action.playerIndex;
    final tile = action.tile;
    var player = state.players[pi];

    // Remove tile from hand
    final newHand = player.hand.without(tile);
    final newDiscards = [...player.discards, tile];

    var newPlayer = player.copyWith(
      hand: newHand,
      discards: newDiscards,
      justDrew: () => null,
    );

    // Handle riichi declaration
    bool isRiichiDiscard = action.declareRiichi;
    if (isRiichiDiscard) {
      final isDoubleRiichi = state.isFirstGoAround && player.discards.isEmpty;
      newPlayer = newPlayer.copyWith(
        isRiichi: true,
        isDoubleRiichi: isDoubleRiichi,
        isIppatsuEligible: true,
        riichiDiscardIndex: () => newPlayer.discards.length - 1,
      );
    }

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = newPlayer;

    final events = <GameEvent>[
      ...state.eventLog,
      TileDiscardedEvent(pi, tile, isRiichi: isRiichiDiscard),
      if (isRiichiDiscard) RiichiDeclaredEvent(pi),
    ];

    return state.copyWith(
      players: newPlayers,
      phase: RoundPhase.awaitingCalls,
      lastDiscardedTile: () => tile,
      lastDiscardedBy: () => pi,
      isFirstGoAround: state.isFirstGoAround && !isRiichiDiscard,
      eventLog: events,
    );
  }

  /// Process a chi call.
  static RoundState processChi(RoundState state, ChiAction action) {
    final pi = action.playerIndex;
    var player = state.players[pi];
    final calledTile = action.calledTile;

    // Remove tiles from hand
    var newHand = List<Tile>.from(player.hand);
    newHand = newHand.without(action.handTile1);
    newHand = newHand.without(action.handTile2);

    // Create meld
    final meldTiles = [action.handTile1, action.handTile2, calledTile];
    meldTiles.sort((a, b) => a.kind.compareTo(b.kind));
    final meld = Meld(
      type: MeldType.chi,
      tiles: meldTiles,
      calledFrom: state.lastDiscardedBy,
      calledTile: calledTile,
    );

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = player.copyWith(
      hand: newHand,
      melds: [...player.melds, meld],
      justDrew: () => null,
    );

    // Clear ippatsu for all players
    _clearIppatsu(newPlayers);

    return state.copyWith(
      players: newPlayers,
      currentTurn: pi,
      phase: RoundPhase.playerTurn,
      lastDiscardedTile: () => null,
      lastDiscardedBy: () => null,
      isFirstGoAround: false,
      eventLog: [...state.eventLog, CallMadeEvent(pi, meld)],
    );
  }

  /// Process a pon call.
  static RoundState processPon(RoundState state, PonAction action) {
    final pi = action.playerIndex;
    var player = state.players[pi];

    var newHand = List<Tile>.from(player.hand);
    newHand = newHand.without(action.handTile1);
    newHand = newHand.without(action.handTile2);

    final meld = Meld(
      type: MeldType.pon,
      tiles: [action.handTile1, action.handTile2, action.calledTile],
      calledFrom: state.lastDiscardedBy,
      calledTile: action.calledTile,
    );

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = player.copyWith(
      hand: newHand,
      melds: [...player.melds, meld],
      justDrew: () => null,
    );

    _clearIppatsu(newPlayers);

    return state.copyWith(
      players: newPlayers,
      currentTurn: pi,
      phase: RoundPhase.playerTurn,
      lastDiscardedTile: () => null,
      lastDiscardedBy: () => null,
      isFirstGoAround: false,
      eventLog: [...state.eventLog, CallMadeEvent(pi, meld)],
    );
  }

  /// Process an open kan (daiminkan).
  static RoundState processOpenKan(RoundState state, OpenKanAction action) {
    final pi = action.playerIndex;
    var player = state.players[pi];

    var newHand = List<Tile>.from(player.hand);
    for (final t in action.handTiles) {
      newHand = newHand.without(t);
    }

    final meld = Meld(
      type: MeldType.openKan,
      tiles: [...action.handTiles, action.calledTile],
      calledFrom: state.lastDiscardedBy,
      calledTile: action.calledTile,
    );

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = player.copyWith(
      hand: newHand,
      melds: [...player.melds, meld],
      justDrew: () => null,
    );

    _clearIppatsu(newPlayers);
    state.wall.revealNewDoraIndicator();

    // Draw from dead wall
    final deadWallTile = state.wall.drawFromDeadWall();
    if (deadWallTile != null) {
      newPlayers[pi] = newPlayers[pi].copyWith(
        hand: [...newPlayers[pi].hand, deadWallTile],
        justDrew: () => deadWallTile,
      );
    }

    return state.copyWith(
      players: newPlayers,
      currentTurn: pi,
      phase: RoundPhase.playerTurn,
      lastDiscardedTile: () => null,
      lastDiscardedBy: () => null,
      isFirstGoAround: false,
      kanCount: state.kanCount + 1,
      eventLog: [
        ...state.eventLog,
        CallMadeEvent(pi, meld),
        if (deadWallTile != null) TileDrawnEvent(pi, deadWallTile, fromDeadWall: true),
      ],
    );
  }

  /// Process a closed kan (ankan).
  static RoundState processClosedKan(RoundState state, ClosedKanAction action) {
    final pi = action.playerIndex;
    var player = state.players[pi];

    final kanTiles = player.hand.where((t) => t.kind == action.tileKind).toList();
    var newHand = List<Tile>.from(player.hand);
    for (final t in kanTiles) {
      newHand = newHand.without(t);
    }

    final meld = Meld(
      type: MeldType.closedKan,
      tiles: kanTiles,
    );

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = player.copyWith(
      hand: newHand,
      melds: [...player.melds, meld],
      justDrew: () => null,
    );

    _clearIppatsu(newPlayers);
    state.wall.revealNewDoraIndicator();

    final deadWallTile = state.wall.drawFromDeadWall();
    if (deadWallTile != null) {
      newPlayers[pi] = newPlayers[pi].copyWith(
        hand: [...newPlayers[pi].hand, deadWallTile],
        justDrew: () => deadWallTile,
      );
    }

    return state.copyWith(
      players: newPlayers,
      phase: RoundPhase.playerTurn,
      isFirstGoAround: false,
      kanCount: state.kanCount + 1,
      eventLog: [
        ...state.eventLog,
        CallMadeEvent(pi, meld),
        if (deadWallTile != null) TileDrawnEvent(pi, deadWallTile, fromDeadWall: true),
      ],
    );
  }

  /// Process an added kan (shouminkan / kakan).
  static RoundState processAddedKan(RoundState state, AddedKanAction action) {
    final pi = action.playerIndex;
    var player = state.players[pi];

    var newHand = List<Tile>.from(player.hand);
    newHand = newHand.without(action.addedTile);

    // Upgrade the pon to an added kan
    final newMelds = List<Meld>.from(player.melds);
    final oldMeld = newMelds[action.meldIndex];
    newMelds[action.meldIndex] = oldMeld.copyWith(
      type: MeldType.addedKan,
      tiles: [...oldMeld.tiles, action.addedTile],
    );

    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[pi] = player.copyWith(
      hand: newHand,
      melds: newMelds,
      justDrew: () => null,
    );

    _clearIppatsu(newPlayers);
    state.wall.revealNewDoraIndicator();

    final deadWallTile = state.wall.drawFromDeadWall();
    if (deadWallTile != null) {
      newPlayers[pi] = newPlayers[pi].copyWith(
        hand: [...newPlayers[pi].hand, deadWallTile],
        justDrew: () => deadWallTile,
      );
    }

    return state.copyWith(
      players: newPlayers,
      phase: RoundPhase.playerTurn,
      isFirstGoAround: false,
      kanCount: state.kanCount + 1,
      eventLog: [
        ...state.eventLog,
        CallMadeEvent(pi, newMelds[action.meldIndex]),
        if (deadWallTile != null) TileDrawnEvent(pi, deadWallTile, fromDeadWall: true),
      ],
    );
  }

  /// Move to the next player's turn.
  static RoundState advanceToNextPlayer(RoundState state) {
    final nextPlayer = (state.currentTurn + 1) % 4;

    // Clear temporary furiten flags for the player whose turn is starting
    final newPlayers = List<PlayerState>.from(state.players);
    newPlayers[nextPlayer] = newPlayers[nextPlayer].copyWith(
      hasDeclinedRon: false,
    );

    // Draw a tile for the next player
    final tile = state.wall.draw();
    if (tile == null) {
      return _handleExhaustiveDraw(state);
    }

    newPlayers[nextPlayer] = newPlayers[nextPlayer].copyWith(
      hand: [...newPlayers[nextPlayer].hand, tile],
      justDrew: () => tile,
    );

    return state.copyWith(
      players: newPlayers,
      currentTurn: nextPlayer,
      phase: RoundPhase.playerTurn,
      lastDiscardedTile: () => null,
      lastDiscardedBy: () => null,
      turnCount: state.turnCount + 1,
      eventLog: [...state.eventLog, TileDrawnEvent(nextPlayer, tile)],
    );
  }

  /// Handle a player declining a ron opportunity (for furiten tracking).
  static RoundState declineRon(RoundState state, int playerIndex) {
    return state.updatePlayer(playerIndex, (p) => p.copyWith(
      hasDeclinedRon: true,
    ));
  }

  /// Handle tsumo win.
  static RoundState processTsumo(RoundState state, int playerIndex) {
    return state.copyWith(
      phase: RoundPhase.roundOver,
      endReason: RoundEndReason.tsumo,
      winnerIndex: () => playerIndex,
      eventLog: [...state.eventLog, TsumoEvent(playerIndex)],
    );
  }

  /// Handle ron win.
  static RoundState processRon(RoundState state, int winnerIndex) {
    return state.copyWith(
      phase: RoundPhase.roundOver,
      endReason: RoundEndReason.ron,
      winnerIndex: () => winnerIndex,
      loserIndex: () => state.lastDiscardedBy,
      eventLog: [
        ...state.eventLog,
        RonEvent(winnerIndex, state.lastDiscardedBy!),
      ],
    );
  }

  /// Handle exhaustive draw.
  static RoundState _handleExhaustiveDraw(RoundState state) {
    final tenpaiList = <bool>[];
    for (final player in state.players) {
      tenpaiList.add(TenpaiDetector.isTenpai(
        List.from(player.kindCounts),
        player.melds.length,
      ));
    }

    return state.copyWith(
      phase: RoundPhase.roundOver,
      endReason: RoundEndReason.exhaustiveDraw,
      eventLog: [...state.eventLog, ExhaustiveDrawEvent(tenpaiList)],
    );
  }

  /// Handle abortive draw.
  static RoundState processAbort(RoundState state, String reason) {
    return state.copyWith(
      phase: RoundPhase.roundOver,
      endReason: RoundEndReason.abortiveDraw,
      eventLog: [...state.eventLog, AbortiveDrawEvent(reason)],
    );
  }

  /// Calculate score changes for exhaustive draw (tenpai/noten payments).
  static List<int> calculateExhaustiveDrawPayments(RoundState state) {
    final changes = List<int>.filled(4, 0);
    final tenpaiPlayers = <int>[];
    final notenPlayers = <int>[];

    for (int i = 0; i < 4; i++) {
      final player = state.players[i];
      if (TenpaiDetector.isTenpai(
        List.from(player.kindCounts),
        player.melds.length,
      )) {
        tenpaiPlayers.add(i);
      } else {
        notenPlayers.add(i);
      }
    }

    if (tenpaiPlayers.isEmpty || tenpaiPlayers.length == 4) {
      return changes; // no payments
    }

    // Total pool is 3000 points
    final totalPool = 3000;
    final perTenpai = totalPool ~/ tenpaiPlayers.length;
    final perNoten = totalPool ~/ notenPlayers.length;

    for (final i in tenpaiPlayers) {
      changes[i] = perTenpai;
    }
    for (final i in notenPlayers) {
      changes[i] = -perNoten;
    }

    return changes;
  }

  static void _clearIppatsu(List<PlayerState> players) {
    for (int i = 0; i < players.length; i++) {
      if (players[i].isIppatsuEligible) {
        players[i] = players[i].copyWith(isIppatsuEligible: false);
      }
    }
  }
}
