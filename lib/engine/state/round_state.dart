import '../tile/tile.dart';
import 'player_state.dart';
import 'wall.dart';
import 'game_event.dart';

enum RoundPhase {
  notStarted,
  playerTurn,
  awaitingCalls,
  roundOver,
}

/// Describes why the round ended.
enum RoundEndReason {
  tsumo,
  ron,
  exhaustiveDraw,
  abortiveDraw,
}

/// Complete state of one round (kyoku).
class RoundState {
  final Wall wall;
  final List<PlayerState> players;
  final int currentTurn; // 0-3: whose turn it is
  final RoundPhase phase;
  final Tile? lastDiscardedTile;
  final int? lastDiscardedBy;
  final int roundWind; // 0=East, 1=South
  final int roundNumber; // 0-3 within a wind
  final int dealerIndex;
  final List<GameEvent> eventLog;
  final bool isFirstGoAround; // no calls have been made yet (for double riichi, tenhou, etc.)
  final int turnCount; // total turns elapsed (for chiihou detection)
  final int kanCount; // total kans declared this round
  final RoundEndReason? endReason;
  final int? winnerIndex;
  final int? loserIndex; // for ron

  /// Pending call responses: maps playerIndex → list of possible actions.
  /// When non-empty, the engine is waiting for call decisions.
  final Map<int, List<dynamic>> pendingCalls;

  const RoundState({
    required this.wall,
    required this.players,
    this.currentTurn = 0,
    this.phase = RoundPhase.notStarted,
    this.lastDiscardedTile,
    this.lastDiscardedBy,
    required this.roundWind,
    required this.roundNumber,
    required this.dealerIndex,
    this.eventLog = const [],
    this.isFirstGoAround = true,
    this.turnCount = 0,
    this.kanCount = 0,
    this.endReason,
    this.winnerIndex,
    this.loserIndex,
    this.pendingCalls = const {},
  });

  PlayerState get currentPlayer => players[currentTurn];
  int get tilesRemaining => wall.remaining;

  RoundState copyWith({
    Wall? wall,
    List<PlayerState>? players,
    int? currentTurn,
    RoundPhase? phase,
    Tile? Function()? lastDiscardedTile,
    int? Function()? lastDiscardedBy,
    int? roundWind,
    int? roundNumber,
    int? dealerIndex,
    List<GameEvent>? eventLog,
    bool? isFirstGoAround,
    int? turnCount,
    int? kanCount,
    RoundEndReason? endReason,
    int? Function()? winnerIndex,
    int? Function()? loserIndex,
    Map<int, List<dynamic>>? pendingCalls,
  }) {
    return RoundState(
      wall: wall ?? this.wall,
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      phase: phase ?? this.phase,
      lastDiscardedTile: lastDiscardedTile != null
          ? lastDiscardedTile()
          : this.lastDiscardedTile,
      lastDiscardedBy: lastDiscardedBy != null
          ? lastDiscardedBy()
          : this.lastDiscardedBy,
      roundWind: roundWind ?? this.roundWind,
      roundNumber: roundNumber ?? this.roundNumber,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      eventLog: eventLog ?? this.eventLog,
      isFirstGoAround: isFirstGoAround ?? this.isFirstGoAround,
      turnCount: turnCount ?? this.turnCount,
      kanCount: kanCount ?? this.kanCount,
      endReason: endReason ?? this.endReason,
      winnerIndex: winnerIndex != null ? winnerIndex() : this.winnerIndex,
      loserIndex: loserIndex != null ? loserIndex() : this.loserIndex,
      pendingCalls: pendingCalls ?? this.pendingCalls,
    );
  }

  /// Returns a copy with one player's state updated.
  RoundState updatePlayer(int index, PlayerState Function(PlayerState) updater) {
    final newPlayers = List<PlayerState>.from(players);
    newPlayers[index] = updater(newPlayers[index]);
    return copyWith(players: newPlayers);
  }
}
