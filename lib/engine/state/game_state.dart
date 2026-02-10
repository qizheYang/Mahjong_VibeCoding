import 'game_config.dart';
import 'round_state.dart';

class GameState {
  final GameConfig config;
  final List<int> scores;
  final int dealerIndex;
  final int roundWind; // 0=East, 1=South
  final int roundNumber; // 0-3 within a wind
  final int honbaCount;
  final int riichiSticksOnTable;
  final RoundState? currentRound;
  final bool isGameOver;

  const GameState({
    required this.config,
    required this.scores,
    this.dealerIndex = 0,
    this.roundWind = 0,
    this.roundNumber = 0,
    this.honbaCount = 0,
    this.riichiSticksOnTable = 0,
    this.currentRound,
    this.isGameOver = false,
  });

  factory GameState.initial(GameConfig config) {
    return GameState(
      config: config,
      scores: List.filled(4, config.startingScore),
    );
  }

  /// Display string like "East 1" or "South 3".
  String get roundDisplayName {
    final windName = roundWind == 0 ? 'East' : 'South';
    return '$windName ${roundNumber + 1}';
  }

  GameState copyWith({
    GameConfig? config,
    List<int>? scores,
    int? dealerIndex,
    int? roundWind,
    int? roundNumber,
    int? honbaCount,
    int? riichiSticksOnTable,
    RoundState? Function()? currentRound,
    bool? isGameOver,
  }) {
    return GameState(
      config: config ?? this.config,
      scores: scores ?? this.scores,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      roundWind: roundWind ?? this.roundWind,
      roundNumber: roundNumber ?? this.roundNumber,
      honbaCount: honbaCount ?? this.honbaCount,
      riichiSticksOnTable: riichiSticksOnTable ?? this.riichiSticksOnTable,
      currentRound: currentRound != null ? currentRound() : this.currentRound,
      isGameOver: isGameOver ?? this.isGameOver,
    );
  }
}
