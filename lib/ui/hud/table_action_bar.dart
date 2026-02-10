import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../models/table_state.dart';

/// Always-visible action bar for the free-form mahjong table.
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
    final mySeat = this.mySeat;
    final seat = tableState.seats[mySeat];
    final hasSelection = selectedTileIds.isNotEmpty;
    final isMyTurn = tableState.currentTurn == mySeat;
    final lastBy = tableState.lastDiscardedBy;
    final prevPlayer = (mySeat - 1 + 4) % 4;
    final canChi = lastBy == prevPlayer;
    final canCallOther = lastBy != null && lastBy != mySeat;

    return Container(
      color: const Color(0xDD0A1A0A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Primary play actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _actionBtn(tr('draw', lang), 'draw', Colors.blue,
                      enabled: isMyTurn),
                  _actionBtn(tr('drawDeadWall', lang), 'drawDeadWall',
                      Colors.blueGrey,
                      enabled: isMyTurn),
                  _actionBtn(
                    tr('discard', lang),
                    'discard',
                    Colors.orange,
                    enabled: hasSelection,
                  ),
                  _callBtn(tr('chi', lang), 'chi', Colors.green,
                      enabled: canChi),
                  _callBtn(tr('pon', lang), 'pon', Colors.teal,
                      enabled: canCallOther),
                  _kanMenuBtn(enableOpen: canCallOther),
                  _actionBtn(
                    tr('riichi', lang),
                    'riichi',
                    Colors.red,
                    enabled: hasSelection && !seat.isRiichi,
                  ),
                  _actionBtn(tr('win', lang), 'win', Colors.amber),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Row 2: Management + social
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _actionBtn(
                      tr('revealDora', lang), 'revealDora', Colors.purple),
                  _actionBtn(tr('sortHand', lang), 'sortHand', Colors.grey),
                  _actionBtn(
                    seat.handRevealed
                        ? tr('hideHand', lang)
                        : tr('showHand', lang),
                    seat.handRevealed ? 'hideHand' : 'showHand',
                    Colors.cyan,
                  ),
                  _actionBtn(
                      tr('undoDiscard', lang), 'undoDiscard', Colors.brown,
                      enabled: lastBy == mySeat),
                  _actionBtn(
                      tr('objection', lang), 'objection', Colors.redAccent),
                  _actionBtn(
                      tr('exchange', lang), 'exchange', Colors.greenAccent),
                  _actionBtn(
                      tr('newRound', lang), 'newRound', Colors.white70),
                ],
              ),
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

  Widget _actionBtn(String label, String action, Color color,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: enabled ? () => onAction(action) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: enabled ? 0.8 : 0.3),
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

  Widget _callBtn(String label, String mode, Color color,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: enabled ? () => onCallMode(mode) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: enabled ? 0.8 : 0.3),
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
