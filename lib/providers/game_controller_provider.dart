import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/ai/basic_ai.dart';
import '../engine/game/game_controller.dart';
import '../engine/state/action.dart';
import '../engine/state/game_config.dart';
import '../engine/state/game_state.dart';
import '../engine/state/round_state.dart';
import '../engine/scoring/score_result.dart';

/// Notifier wrapping the GameController for Riverpod state management.
class GameControllerNotifier extends StateNotifier<GameState> {
  final GameController _controller;
  final BasicAi _ai = BasicAi();

  GameControllerNotifier()
      : _controller = GameController(),
        super(GameState.initial(const GameConfig()));

  ScoreResult? get lastScoreResult => _controller.lastScoreResult;
  List<int>? get lastDrawChanges => _controller.lastDrawChanges;
  List<bool>? get lastTenpaiList => _controller.lastTenpaiList;

  Future<void> startGame(GameConfig config) async {
    _controller.startGame(config);
    state = _controller.state;
    await _processAiTurns();
  }

  Future<void> startNewRound() async {
    _controller.startNewRound();
    state = _controller.state;
    await _processAiTurns();
  }

  List<PlayerAction> getAvailableActions(int playerIndex) {
    return _controller.getAvailableActions(playerIndex);
  }

  /// Process a human player's action, then auto-play AI turns.
  Future<void> submitAction(PlayerAction action) async {
    _controller.processAction(action);
    state = _controller.state;

    // Process AI call responses if needed
    await _processAiCalls();

    // Process AI turns until it's the human's turn again
    await _processAiTurns();
  }

  Future<void> _processAiCalls() async {
    // Check if any AI players need to respond to calls
    for (int i = 1; i < 4; i++) {
      if (_controller.isWaitingForPlayer(i)) {
        final actions = _controller.getAvailableActions(i);
        if (actions.isNotEmpty) {
          final round = _controller.state.currentRound;
          if (round != null) {
            final decision = _ai.decideAction(round, i, actions);
            _controller.processAction(decision);
            state = _controller.state;
          }
        }
      }
    }
  }

  Future<void> _processAiTurns() async {
    while (true) {
      final round = _controller.state.currentRound;
      if (round == null) break;
      if (round.phase == RoundPhase.roundOver) break;
      if (_controller.state.isGameOver) break;

      final currentTurn = round.currentTurn;
      if (currentTurn == 0) {
        // It's the human's turn — check if there are pending calls for human
        if (_controller.isWaitingForPlayer(0)) break;
        if (round.phase == RoundPhase.playerTurn) break;
      }

      if (currentTurn != 0 && round.phase == RoundPhase.playerTurn) {
        // AI player's turn
        final actions = _controller.getAvailableActions(currentTurn);
        if (actions.isEmpty) break;

        final decision = _ai.decideAction(round, currentTurn, actions);
        _controller.processAction(decision);
        state = _controller.state;

        // Process any resulting calls
        await _processAiCalls();

        // Small delay for visual pacing
        await Future.delayed(const Duration(milliseconds: 200));
      } else if (round.phase == RoundPhase.awaitingCalls) {
        // Check if human has calls available
        if (_controller.isWaitingForPlayer(0)) break;

        // Process remaining AI calls
        await _processAiCalls();

        // If still awaiting and no human involvement, something is stuck
        if (_controller.state.currentRound?.phase == RoundPhase.awaitingCalls) {
          break;
        }
      } else {
        break;
      }
    }
  }

  /// Check if the human player has available call actions.
  bool get humanHasCalls => _controller.isWaitingForPlayer(0);

  /// Get human player's available actions.
  List<PlayerAction> get humanActions => getAvailableActions(0);
}

/// Main game controller provider.
final gameControllerProvider =
    StateNotifierProvider<GameControllerNotifier, GameState>(
  (ref) => GameControllerNotifier(),
);

/// Derived: current round state.
final currentRoundProvider = Provider<RoundState?>((ref) {
  return ref.watch(gameControllerProvider).currentRound;
});

/// Derived: human player's available actions.
final humanActionsProvider = Provider<List<PlayerAction>>((ref) {
  final notifier = ref.watch(gameControllerProvider.notifier);
  final round = ref.watch(currentRoundProvider);
  if (round == null) return [];
  if (round.phase == RoundPhase.roundOver) return [];
  return notifier.humanActions;
});
