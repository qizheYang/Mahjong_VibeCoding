import 'dart:math';
import '../state/action.dart';
import '../state/game_config.dart';
import '../state/game_state.dart';
import '../state/round_state.dart';
import '../yaku/hand_context.dart';
import '../yaku/yaku_evaluator.dart';
import '../scoring/han_counter.dart';
import '../scoring/fu_calculator.dart';
import '../scoring/score_table.dart';
import '../scoring/payment_calculator.dart';
import '../scoring/score_result.dart';
import '../win/tenpai_detector.dart';
import 'action_validator.dart';
import 'call_resolver.dart';
import 'round_flow.dart';
import 'turn_manager.dart';

/// Orchestrates the game: processes actions, advances state, manages rounds.
class GameController {
  GameState _state;
  final Random _random;

  /// Pending call responses from players.
  final Map<int, PlayerAction> _pendingResponses = {};

  /// Players who have available call actions this turn.
  final Set<int> _playersWithCalls = {};

  GameController({GameConfig? config, Random? random})
      : _random = random ?? Random(),
        _state = GameState.initial(config ?? const GameConfig());

  GameState get state => _state;

  /// Start a new game.
  void startGame([GameConfig? config]) {
    _state = GameState.initial(config ?? _state.config);
    startNewRound();
  }

  /// Start a new round.
  void startNewRound() {
    if (_state.isGameOver) return;

    final round = RoundFlow.deal(
      roundWind: _state.roundWind,
      roundNumber: _state.roundNumber,
      dealerIndex: _state.dealerIndex,
      random: _random,
    );

    _state = _state.copyWith(currentRound: () => round);
    _pendingResponses.clear();
    _playersWithCalls.clear();
  }

  /// Get available actions for a player.
  List<PlayerAction> getAvailableActions(int playerIndex) {
    final round = _state.currentRound;
    if (round == null) return [];
    return ActionValidator.getAvailableActions(round, playerIndex);
  }

  /// Process an action from a player (human or AI).
  void processAction(PlayerAction action) {
    final round = _state.currentRound;
    if (round == null || round.phase == RoundPhase.roundOver) return;

    if (round.phase == RoundPhase.awaitingCalls) {
      _handleCallResponse(action);
      return;
    }

    if (round.phase == RoundPhase.playerTurn) {
      _handleTurnAction(action);
      return;
    }
  }

  void _handleTurnAction(PlayerAction action) {
    var round = _state.currentRound!;

    switch (action) {
      case TsumoAction():
        round = RoundFlow.processTsumo(round, action.playerIndex);
        _state = _state.copyWith(currentRound: () => round);
        _resolveRoundEnd();

      case DiscardAction():
        // Handle riichi cost
        if (action.declareRiichi) {
          final scores = List<int>.from(_state.scores);
          scores[action.playerIndex] -= 1000;
          _state = _state.copyWith(
            scores: scores,
            riichiSticksOnTable: _state.riichiSticksOnTable + 1,
          );
        }

        round = RoundFlow.discard(round, action);
        _state = _state.copyWith(currentRound: () => round);

        // Check if any other player can call
        _checkForCalls();

      case ClosedKanAction():
        round = RoundFlow.processClosedKan(round, action);
        _state = _state.copyWith(currentRound: () => round);

      case AddedKanAction():
        // Check for chankan (robbing the kan) before processing
        round = RoundFlow.processAddedKan(round, action);
        _state = _state.copyWith(currentRound: () => round);

      case AbortAction():
        round = RoundFlow.processAbort(round, action.reason.name);
        _state = _state.copyWith(currentRound: () => round);
        _resolveRoundEnd();

      default:
        break;
    }
  }

  void _checkForCalls() {
    final round = _state.currentRound!;
    _pendingResponses.clear();
    _playersWithCalls.clear();

    for (int i = 0; i < 4; i++) {
      if (i == round.lastDiscardedBy) continue;
      final actions = ActionValidator.getAvailableActions(round, i);
      // Filter to only call-relevant actions (not Skip alone)
      final callActions = actions.where((a) => a is! SkipAction).toList();
      if (callActions.isNotEmpty) {
        _playersWithCalls.add(i);
      }
    }

    if (_playersWithCalls.isEmpty) {
      // No calls possible — advance to next player
      _advanceToNextPlayer();
    }
    // Otherwise, wait for call decisions (AI will be triggered by the provider)
  }

  void _handleCallResponse(PlayerAction action) {
    final pi = action.playerIndex;
    _pendingResponses[pi] = action;

    // Track declined ron for furiten
    if (action is SkipAction && _playersWithCalls.contains(pi)) {
      final available = getAvailableActions(pi);
      if (available.any((a) => a is RonAction)) {
        var round = _state.currentRound!;
        round = RoundFlow.declineRon(round, pi);
        _state = _state.copyWith(currentRound: () => round);
      }
    }

    // Check if all players with calls have responded
    if (_playersWithCalls.every((p) => _pendingResponses.containsKey(p))) {
      _resolveCallResponses();
    }
  }

  void _resolveCallResponses() {
    final resolved = CallResolver.resolve(_pendingResponses);
    _pendingResponses.clear();

    if (resolved == null) {
      // Everyone skipped
      _advanceToNextPlayer();
      return;
    }

    var round = _state.currentRound!;

    switch (resolved) {
      case RonAction():
        round = RoundFlow.processRon(round, resolved.playerIndex);
        _state = _state.copyWith(currentRound: () => round);
        _resolveRoundEnd();

      case PonAction():
        round = RoundFlow.processPon(round, resolved);
        _state = _state.copyWith(currentRound: () => round);

      case ChiAction():
        round = RoundFlow.processChi(round, resolved);
        _state = _state.copyWith(currentRound: () => round);

      case OpenKanAction():
        round = RoundFlow.processOpenKan(round, resolved);
        _state = _state.copyWith(currentRound: () => round);

      case AbortAction():
        round = RoundFlow.processAbort(round, resolved.reason.name);
        _state = _state.copyWith(currentRound: () => round);
        _resolveRoundEnd();

      default:
        _advanceToNextPlayer();
    }
  }

  void _advanceToNextPlayer() {
    var round = _state.currentRound!;
    round = RoundFlow.advanceToNextPlayer(round);
    _state = _state.copyWith(currentRound: () => round);

    if (round.phase == RoundPhase.roundOver) {
      _resolveRoundEnd();
    }
  }

  void _resolveRoundEnd() {
    final round = _state.currentRound!;
    if (round.endReason == null) return;

    // Clear pending call state
    _playersWithCalls.clear();
    _pendingResponses.clear();

    switch (round.endReason!) {
      case RoundEndReason.tsumo:
      case RoundEndReason.ron:
        _resolveWin();
      case RoundEndReason.exhaustiveDraw:
        _resolveExhaustiveDraw();
      case RoundEndReason.abortiveDraw:
        _resolveAbortiveDraw();
    }
  }

  void _resolveWin() {
    final round = _state.currentRound!;
    final winnerIndex = round.winnerIndex!;
    final winner = round.players[winnerIndex];
    final isTsumo = round.endReason == RoundEndReason.tsumo;

    // Build hand context — for ron, include the winning tile in the closed hand
    final closedHandTiles = isTsumo
        ? winner.hand
        : [...winner.hand, round.lastDiscardedTile!];
    final ctx = HandContext(
      closedHandTiles: closedHandTiles,
      melds: winner.melds,
      winningTile: isTsumo
          ? winner.justDrew ?? winner.hand.last
          : round.lastDiscardedTile!,
      isTsumo: isTsumo,
      isRiichi: winner.isRiichi,
      isDoubleRiichi: winner.isDoubleRiichi,
      isIppatsu: winner.isIppatsuEligible,
      seatWind: winner.seatWind,
      roundWind: round.roundWind,
      isFirstTurn: round.turnCount <= 4 && round.isFirstGoAround,
      isLastTile: round.wall.remaining == 0,
      isAfterKan: false, // TODO: track properly
      doraIndicators: round.wall.doraIndicators,
      uraDoraIndicators: round.wall.uraDoraIndicators,
      turnCount: round.turnCount,
    );

    // Evaluate yaku
    final yakuResult = YakuEvaluator.evaluate(ctx);

    if (!yakuResult.hasYaku) {
      // No yaku — this shouldn't happen if validation is correct
      // Treat as abortive draw
      _resolveAbortiveDraw();
      return;
    }

    // Calculate scoring
    final han = HanCounter.count(yakuResult.yakuList, ctx);
    final fu = yakuResult.isChiitoitsuForm
        ? FuCalculator.chiitoitsuFu()
        : (yakuResult.partition != null
            ? FuCalculator.calculate(yakuResult.partition!, ctx)
            : 30);

    final payment = PaymentCalculator.calculateWithDealer(
      han: han,
      fu: fu,
      dealerIndex: round.dealerIndex,
      isTsumo: isTsumo,
      winnerIndex: winnerIndex,
      loserIndex: round.loserIndex,
      honba: _state.honbaCount,
      riichiSticksOnTable: _state.riichiSticksOnTable,
    );

    // Advance to next round
    _state = TurnManager.advanceRound(
      _state,
      round.endReason!,
      winnerIndex: winnerIndex,
      scoreChanges: payment.scoreChanges,
      riichiSticksCollected: isTsumo ? _state.riichiSticksOnTable : _state.riichiSticksOnTable,
    );

    // Store the round result for display
    _lastDrawChanges = null;
    _lastTenpaiList = null;
    _lastScoreResult = ScoreResult(
      yakuList: yakuResult.yakuList,
      han: han,
      fu: fu,
      doraCount: HanCounter.countRegularDora(ctx),
      uraDoraCount: HanCounter.countUraDora(ctx),
      redDoraCount: HanCounter.countRedDora(ctx),
      tierName: ScoreTable.tierName(han, fu),
      payment: payment,
    );
  }

  void _resolveExhaustiveDraw() {
    final round = _state.currentRound!;
    final payments = RoundFlow.calculateExhaustiveDrawPayments(round);

    // Store tenpai info for display
    _lastTenpaiList = <bool>[];
    for (final player in round.players) {
      _lastTenpaiList!.add(TenpaiDetector.isTenpai(
        List.from(player.kindCounts),
        player.melds.length,
      ));
    }
    _lastDrawChanges = payments;

    _state = TurnManager.advanceRound(
      _state,
      RoundEndReason.exhaustiveDraw,
      winnerIndex: null,
      scoreChanges: payments,
      riichiSticksCollected: 0,
    );
    _lastScoreResult = null;
  }

  void _resolveAbortiveDraw() {
    _state = TurnManager.advanceRound(
      _state,
      RoundEndReason.abortiveDraw,
      winnerIndex: null,
      scoreChanges: List.filled(4, 0),
      riichiSticksCollected: 0,
    );
    _lastScoreResult = null;
    _lastDrawChanges = null;
    _lastTenpaiList = null;
  }

  /// The result of the last completed round (for display).
  ScoreResult? _lastScoreResult;
  ScoreResult? get lastScoreResult => _lastScoreResult;

  /// Draw result info (for display).
  List<int>? _lastDrawChanges;
  List<int>? get lastDrawChanges => _lastDrawChanges;
  List<bool>? _lastTenpaiList;
  List<bool>? get lastTenpaiList => _lastTenpaiList;

  /// Whether the game is waiting for a specific player's call decision.
  bool isWaitingForPlayer(int playerIndex) {
    return _playersWithCalls.contains(playerIndex) &&
        !_pendingResponses.containsKey(playerIndex);
  }

  /// Players who still need to respond to calls.
  Set<int> get pendingCallPlayers {
    return _playersWithCalls.difference(_pendingResponses.keys.toSet());
  }
}
