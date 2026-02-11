import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/table_state.dart';

/// Action bar for the free-form mahjong table.
///
/// Buttons only appear when they are relevant to the current game state.
/// Auto toggles and dora flip are handled elsewhere.
class TableActionBar extends StatelessWidget {
  final TableState tableState;
  final int mySeat;
  final String? callMode;
  final Set<int> selectedTileIds;
  final ValueChanged<String> onAction;
  final ValueChanged<String> onCallMode;
  final VoidCallback onCancelCall;
  final VoidCallback onConfirmCall;
  final Lang lang;

  const TableActionBar({
    super.key,
    required this.tableState,
    required this.mySeat,
    this.callMode,
    required this.selectedTileIds,
    required this.onAction,
    required this.onCallMode,
    required this.onCancelCall,
    required this.onConfirmCall,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    if (callMode != null) {
      return _buildCallModeBar();
    }
    return _buildNormalBar();
  }

  Widget _buildNormalBar() {
    final seat = tableState.seats[mySeat];
    final hasSelection = selectedTileIds.isNotEmpty;
    final isMyTurn = tableState.currentTurn == mySeat;
    final hasDrawn = tableState.hasDrawnThisTurn;
    final lastBy = tableState.lastDiscardedBy;
    final prevPlayer = (mySeat - 1 + 4) % 4;
    final canChi = lastBy == prevPlayer;
    final canCallOther = lastBy != null && lastBy != mySeat;
    final wallEmpty = tableState.wallRemaining <= 0;

    // Row 1: Play actions (only show when relevant)
    final playActions = <Widget>[];

    if (isMyTurn && !hasDrawn) {
      playActions.add(_actionBtn(tr('draw', lang), 'draw', Colors.blue));
    }
    if (hasSelection) {
      playActions
          .add(_actionBtn(tr('discard', lang), 'discard', Colors.orange));
    }
    if (canChi && !tableState.config.isSichuan) {
      playActions.add(_callBtn(tr('chi', lang), 'chi', Colors.green));
    }
    if (canCallOther) {
      playActions.add(_callBtn(tr('pon', lang), 'pon', Colors.teal));
    }
    playActions.add(_kanMenuBtn(enableOpen: canCallOther));
    if (hasSelection && !seat.isRiichi) {
      playActions.add(_actionBtn(tr('riichi', lang), 'riichi', Colors.red));
    }
    playActions.add(_actionBtn(tr('win', lang), 'win', Colors.amber));
    // 补花: only for variants with flower tiles when a tile is selected
    if (hasSelection && tableState.config.hasFlowers) {
      playActions.add(
          _actionBtn(tr('drawFlower', lang), 'drawFlower', Colors.pink));
    }

    // Row 2: Management actions
    final mgmtActions = <Widget>[
      _actionBtn(tr('sortHand', lang), 'sortHand', Colors.grey),
    ];
    // Show/hide hand: only after riichi or when wall is empty
    if (seat.isRiichi || wallEmpty) {
      mgmtActions.add(_actionBtn(
        seat.handRevealed ? tr('hideHand', lang) : tr('showHand', lang),
        seat.handRevealed ? 'hideHand' : 'showHand',
        Colors.cyan,
      ));
    }
    if (lastBy == mySeat) {
      mgmtActions.add(
          _actionBtn(tr('undoDiscard', lang), 'undoDiscard', Colors.brown));
    }
    mgmtActions.addAll([
      _actionBtn(tr('objection', lang), 'objection', Colors.redAccent),
      _actionBtn(tr('exchange', lang), 'exchange', Colors.greenAccent),
      _actionBtn(tr('newRound', lang), 'newRound', Colors.white70),
    ]);

    return Container(
      color: const Color(0xDD0A1A0A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playActions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: playActions),
              ),
            const SizedBox(height: 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: mgmtActions),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallModeBar() {
    final expectedCount = switch (callMode) {
      'chi' => 2,
      'pon' => 2,
      'openKan' => 3,
      'closedKan' => 4,
      'addedKan' => 1,
      _ => 0,
    };
    final callLabel = switch (callMode) {
      'chi' => tr('chi', lang),
      'pon' => tr('pon', lang),
      'openKan' => tr('openKan', lang),
      'closedKan' => tr('closedKan', lang),
      'addedKan' => tr('addedKan', lang),
      _ => '',
    };

    return Container(
      color: const Color(0xDD1A0A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '$callLabel: ${selectedTileIds.length}/$expectedCount',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onCancelCall,
              child: Text(tr('cancel', lang),
                  style: const TextStyle(color: Colors.white60)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: selectedTileIds.length == expectedCount
                  ? onConfirmCall
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: Text(tr('confirm', lang)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, String action, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () => onAction(action),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _callBtn(String label, String mode, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: () => onCallMode(mode),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: Size.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _kanMenuBtn({bool enableOpen = true}) {
    return PopupMenuButton<String>(
      onSelected: (mode) => onCallMode(mode),
      enabled: true,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'openKan',
          enabled: enableOpen,
          child: Text(tr('openKan', lang)),
        ),
        PopupMenuItem(
          value: 'closedKan',
          child: Text(tr('closedKan', lang)),
        ),
        PopupMenuItem(
          value: 'addedKan',
          child: Text(tr('addedKan', lang)),
        ),
      ],
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.tealAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          tr('kan', lang),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}
