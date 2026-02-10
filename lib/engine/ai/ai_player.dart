import '../state/action.dart';
import '../state/round_state.dart';

/// Interface for AI players.
abstract class AiPlayer {
  /// Decide what action to take given the current round state and legal actions.
  PlayerAction decideAction(
    RoundState state,
    int playerIndex,
    List<PlayerAction> legalActions,
  );
}
