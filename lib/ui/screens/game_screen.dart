import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/tile/tile.dart';
import '../../engine/state/action.dart';
import '../../engine/state/game_state.dart';
import '../../engine/state/round_state.dart';
import '../../providers/game_controller_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../table/table_view.dart';
import '../hud/action_bar.dart';
import '../dialogs/round_result_dialog.dart';
import '../dialogs/game_over_dialog.dart';
import 'title_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showingResult = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final round = gameState.currentRound;
    final uiState = ref.watch(uiStateProvider);
    final actions = ref.watch(humanActionsProvider);

    // Check if round just ended
    if (round != null &&
        round.phase == RoundPhase.roundOver &&
        !_showingResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRoundResult();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main table
          if (round != null)
            TableView(
              gameState: gameState,
              selectedTile: uiState.selectedTile,
              onTileTap: _onTileTap,
            ),

          // Action bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ActionBar(
              availableActions: actions,
              onAction: _onAction,
            ),
          ),
        ],
      ),
    );
  }

  void _onTileTap(Tile tile) {
    final uiNotifier = ref.read(uiStateProvider.notifier);
    final uiState = ref.read(uiStateProvider);
    final actions = ref.read(humanActionsProvider);

    // If the tile is already selected, discard it
    if (uiState.selectedTile == tile) {
      final discardAction = actions
          .whereType<DiscardAction>()
          .where((a) => a.tile == tile && !a.declareRiichi)
          .firstOrNull;
      if (discardAction != null) {
        _onAction(discardAction);
        uiNotifier.selectTile(null);
        return;
      }
    }

    // Otherwise select the tile
    uiNotifier.selectTile(tile);
  }

  Future<void> _onAction(PlayerAction action) async {
    ref.read(uiStateProvider.notifier).selectTile(null);
    await ref.read(gameControllerProvider.notifier).submitAction(action);
  }

  void _showGameOver(GameState gameState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return GameOverDialog(
          gameState: gameState,
          onPlayAgain: () {
            Navigator.of(ctx).pop();
            _showingResult = false;
            ref.read(gameControllerProvider.notifier).startGame(gameState.config);
          },
          onMainMenu: () {
            Navigator.of(ctx).pop();
            _showingResult = false;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TitleScreen()),
            );
          },
        );
      },
    );
  }

  void _showRoundResult() {
    if (_showingResult) return;
    _showingResult = true;

    final gameState = ref.read(gameControllerProvider);
    final round = gameState.currentRound;
    final notifier = ref.read(gameControllerProvider.notifier);
    final scoreResult = notifier.lastScoreResult;
    final drawChanges = notifier.lastDrawChanges;
    final tenpaiList = notifier.lastTenpaiList;

    if (round == null) {
      _showingResult = false;
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return RoundResultDialog(
          gameState: gameState,
          round: round,
          scoreResult: scoreResult,
          drawScoreChanges: drawChanges,
          tenpaiList: tenpaiList,
          onContinue: () {
            Navigator.of(ctx).pop();
            if (gameState.isGameOver) {
              _showGameOver(gameState);
            } else {
              _showingResult = false;
              ref.read(gameControllerProvider.notifier).startNewRound();
            }
          },
        );
      },
    );
  }
}
