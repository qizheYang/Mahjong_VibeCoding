import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/tile/tile.dart';
import '../../i18n/strings.dart';
import '../../models/table_state.dart';
import '../../models/table_action.dart';
import '../../providers/multiplayer_provider.dart';
import '../table/multiplayer_table_view.dart';
import '../hud/table_action_bar.dart';
import '../dialogs/win_declaration_dialog.dart';
import '../dialogs/exchange_dialog.dart';
import '../dialogs/objection_banner.dart';

class TableScreen extends ConsumerStatefulWidget {
  const TableScreen({super.key});

  @override
  ConsumerState<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends ConsumerState<TableScreen> {
  final Set<int> _selectedTileIds = {};
  String? _callMode;

  /// Timer for auto dora flip + dead wall draw after kan.
  Timer? _kanTimer;

  /// Tracks the last action log length to detect new actions.
  int _lastActionLogLength = 0;

  @override
  void dispose() {
    _kanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableState = ref.watch(tableStateProvider);
    final conn = ref.watch(multiplayerProvider);
    final lang = ref.watch(langProvider);
    final objection = ref.watch(objectionProvider);
    final autoDraw = ref.watch(autoDrawProvider);
    final autoDiscard = ref.watch(autoDiscardProvider);

    // Auto-draw: when it's my turn and I haven't drawn yet
    if (tableState != null && autoDraw) {
      final mySeatIdx = conn.mySeat ?? 0;
      if (tableState.currentTurn == mySeatIdx &&
          !tableState.hasDrawnThisTurn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(multiplayerProvider.notifier)
              .sendAction(TableAction.draw());
        });
      }
    }

    // Auto-discard: when I drew a tile and auto-discard or riichi is active
    if (tableState != null) {
      final mySeatIdx = conn.mySeat ?? 0;
      final seat = tableState.seats[mySeatIdx];
      final justDrew = seat.justDrewTileId;
      if (justDrew != null &&
          tableState.currentTurn == mySeatIdx &&
          (autoDiscard || seat.isRiichi)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(multiplayerProvider.notifier)
              .sendAction(TableAction.discard(justDrew));
        });
      }
    }

    // Detect kan actions and start auto-timer for dora flip + dead wall draw
    if (tableState != null) {
      _detectKanAndAutoProcess(tableState, conn.mySeat ?? 0);
    }

    // Cancel kan timer on objection
    if (objection != null && _kanTimer != null) {
      _kanTimer?.cancel();
      _kanTimer = null;
    }

    if (tableState == null) {
      return Scaffold(
        body: Center(
          child: Text(
            tr('connecting', lang),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF0D3B0D),
      );
    }

    final mySeat = conn.mySeat ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D3B0D),
      body: Column(
        children: [
          // Main table view (fills available space)
          Expanded(
            child: Stack(
              children: [
                MultiplayerTableView(
                  tableState: tableState,
                  mySeat: mySeat,
                  selectedTileIds: _selectedTileIds,
                  callMode: _callMode,
                  onTileTap: _onTileTap,
                  lang: lang,
                  autoDraw: autoDraw,
                  autoDiscard: autoDiscard,
                  onAutoDrawChanged: (v) =>
                      ref.read(autoDrawProvider.notifier).state = v,
                  onAutoDiscardChanged: (v) =>
                      ref.read(autoDiscardProvider.notifier).state = v,
                ),

                // Win proposal overlay
                if (tableState.pendingWin != null)
                  _buildWinProposalOverlay(tableState, mySeat, lang),

                // Exchange proposal overlay
                if (tableState.pendingExchange != null)
                  _buildExchangeOverlay(tableState, mySeat, lang),

                // Objection banner
                if (objection != null &&
                    DateTime.now().difference(objection.timestamp).inSeconds <
                        10)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ObjectionBanner(
                      notification: objection,
                      lang: lang,
                      onDismiss: () {
                        ref.read(objectionProvider.notifier).state = null;
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Action bar at the bottom (no overlap with table)
          TableActionBar(
            tableState: tableState,
            mySeat: mySeat,
            callMode: _callMode,
            selectedTileIds: _selectedTileIds,
            onAction: _onAction,
            onCallMode: _onCallMode,
            onCancelCall: _onCancelCall,
            onConfirmCall: _onConfirmCall,
            lang: lang,
          ),
        ],
      ),
    );
  }

  /// Detect when a kan action happens and auto-send revealDora + drawDeadWall
  /// after 5 seconds, unless an objection is raised.
  void _detectKanAndAutoProcess(TableState state, int mySeat) {
    final logLen = state.actionLog.length;
    if (logLen <= _lastActionLogLength) {
      _lastActionLogLength = logLen;
      return;
    }

    // Check new entries for kan actions by me
    for (int i = _lastActionLogLength; i < logLen; i++) {
      final entry = state.actionLog[i];
      if (['openKan', 'closedKan', 'addedKan'].contains(entry.action) &&
          entry.seat == mySeat) {
        _startKanTimer();
        break;
      }
    }
    _lastActionLogLength = logLen;
  }

  void _startKanTimer() {
    _kanTimer?.cancel();
    final tableState = ref.read(tableStateProvider);
    final hasDora = tableState?.config.hasDora ?? false;

    _kanTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final mp = ref.read(multiplayerProvider.notifier);
      // Only auto reveal dora for Riichi mode
      if (hasDora) {
        mp.sendAction(TableAction.revealDora());
      }
      // Auto draw from dead wall (short delay to let server process dora first)
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        mp.sendAction(TableAction.drawDeadWall());
      });
      _kanTimer = null;
    });
  }

  void _onTileTap(Tile tile) {
    if (_callMode != null) {
      setState(() {
        if (_selectedTileIds.contains(tile.id)) {
          _selectedTileIds.remove(tile.id);
        } else {
          _selectedTileIds.add(tile.id);
        }
      });
    } else {
      setState(() {
        if (_selectedTileIds.contains(tile.id)) {
          _selectedTileIds.clear();
          ref
              .read(multiplayerProvider.notifier)
              .sendAction(TableAction.discard(tile.id));
        } else {
          _selectedTileIds.clear();
          _selectedTileIds.add(tile.id);
        }
      });
    }
  }

  void _onAction(String action) {
    final mp = ref.read(multiplayerProvider.notifier);
    final lang = ref.read(langProvider);

    switch (action) {
      case 'draw':
        mp.sendAction(TableAction.draw());
      case 'discard':
        if (_selectedTileIds.length == 1) {
          mp.sendAction(TableAction.discard(_selectedTileIds.first));
          setState(() => _selectedTileIds.clear());
        }
      case 'riichi':
        if (_selectedTileIds.length == 1) {
          mp.sendAction(TableAction.riichi(_selectedTileIds.first));
          setState(() => _selectedTileIds.clear());
        }
      case 'drawFlower':
        if (_selectedTileIds.length == 1) {
          mp.sendAction(TableAction.drawFlower(_selectedTileIds.first));
          setState(() => _selectedTileIds.clear());
        }
      case 'sortHand':
        mp.sendAction(TableAction.sortHand());
      case 'showHand':
        mp.sendAction(TableAction.showHand());
      case 'hideHand':
        mp.sendAction(TableAction.hideHand());
      case 'undoDiscard':
        mp.sendAction(TableAction.undoDiscard());
      case 'newRound':
        _showNewRoundDialog(lang);
      case 'win':
        _showWinDialog(lang);
      case 'objection':
        _kanTimer?.cancel();
        _kanTimer = null;
        _showObjectionDialog(lang);
      case 'exchange':
        _showExchangeDialog(lang);
      case 'confirmWin':
        mp.sendAction(TableAction.confirmWin());
      case 'rejectWin':
        mp.sendAction(TableAction.rejectWin());
      case 'confirmExchange':
        mp.sendAction(TableAction.exchangeConfirm());
      case 'rejectExchange':
        mp.sendAction(TableAction.exchangeReject());
    }
  }

  void _onCallMode(String mode) {
    setState(() {
      _callMode = mode;
      _selectedTileIds.clear();
    });
  }

  void _onCancelCall() {
    setState(() {
      _callMode = null;
      _selectedTileIds.clear();
    });
  }

  void _onConfirmCall() {
    final mp = ref.read(multiplayerProvider.notifier);
    final ids = _selectedTileIds.toList();

    switch (_callMode) {
      case 'chi':
        if (ids.length == 2) {
          mp.sendAction(TableAction.chi(ids));
        }
      case 'pon':
        if (ids.length == 2) {
          mp.sendAction(TableAction.pon(ids));
        }
      case 'openKan':
        if (ids.length == 3) {
          mp.sendAction(TableAction.openKan(ids));
        }
      case 'closedKan':
        if (ids.length == 4) {
          mp.sendAction(TableAction.closedKan(ids));
        }
      case 'addedKan':
        if (ids.length == 1) {
          final tableState = ref.read(tableStateProvider);
          final mySeat = ref.read(multiplayerProvider).mySeat ?? 0;
          if (tableState != null) {
            final melds = tableState.seats[mySeat].melds;
            final tileKind = ids.first ~/ 4;
            for (int i = 0; i < melds.length; i++) {
              if (melds[i].type == 'pon' &&
                  melds[i].tileIds.any((id) => id ~/ 4 == tileKind)) {
                mp.sendAction(TableAction.addedKan(ids.first, i));
                break;
              }
            }
          }
        }
    }

    setState(() {
      _callMode = null;
      _selectedTileIds.clear();
    });
  }

  // ─── Dialogs ─────────────────────────────────────────────

  void _showWinDialog(Lang lang) {
    showDialog(
      context: context,
      builder: (ctx) => WinDeclarationDialog(
        lang: lang,
        onDeclare: (isTsumo, han, fu) {
          Navigator.of(ctx).pop();
          ref
              .read(multiplayerProvider.notifier)
              .sendAction(TableAction.declareWin(isTsumo, han, fu));
        },
      ),
    );
  }

  void _showObjectionDialog(Lang lang) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A1A),
        title: Text(tr('objection', lang),
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: tr('objectionPlaceholder', lang),
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('cancel', lang),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(multiplayerProvider.notifier)
                  .sendAction(TableAction.objection(controller.text));
            },
            child: Text(tr('confirm', lang),
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showExchangeDialog(Lang lang) {
    final tableState = ref.read(tableStateProvider);
    final mySeat = ref.read(multiplayerProvider).mySeat ?? 0;
    if (tableState == null) return;

    showDialog(
      context: context,
      builder: (ctx) => ExchangeDialog(
        lang: lang,
        nicknames: tableState.nicknames,
        mySeat: mySeat,
        onPropose: (targetSeat, amount) {
          Navigator.of(ctx).pop();
          ref
              .read(multiplayerProvider.notifier)
              .sendAction(TableAction.exchangePropose(targetSeat, amount));
        },
      ),
    );
  }

  void _showNewRoundDialog(Lang lang) {
    final tableState = ref.read(tableStateProvider);
    final keepDealer = tableState?.suggestKeepDealer ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A1A),
        title: Text(tr('newRound', lang),
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('cancel', lang),
                style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(multiplayerProvider.notifier)
                  .sendAction(TableAction.newRound(keepDealer: true));
            },
            child: Text(tr('keepDealer', lang),
                style: TextStyle(
                    color: keepDealer ? Colors.amber : Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(multiplayerProvider.notifier)
                  .sendAction(TableAction.newRound(keepDealer: false));
            },
            child: Text(tr('rotateDealer', lang),
                style: TextStyle(
                    color: !keepDealer ? Colors.amber : Colors.white70)),
          ),
        ],
      ),
    );
  }

  // ─── Overlay builders ────────────────────────────────────

  Widget _buildWinProposalOverlay(
      TableState state, int mySeat, Lang lang) {
    final proposal = state.pendingWin!;
    final isMe = proposal.seatIndex == mySeat;
    final windLabels = [
      tr('east', lang),
      tr('south', lang),
      tr('west', lang),
      tr('north', lang),
    ];

    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEE1A1A3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${windLabels[proposal.seatIndex]} ${state.nicknames[proposal.seatIndex]}',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${tr('declareWin', lang)}: '
              '${proposal.tierName} '
              '${proposal.isTsumo ? tr("tsumo", lang) : tr("ron", lang)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${proposal.totalPoints}${tr("points", lang)}',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${tr("confirm", lang)}: ${proposal.confirmed.length}/2  '
              '${tr("reject", lang)}: ${proposal.rejected.length}/2',
              style:
                  const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            if (!isMe) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _onAction('confirmWin'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: Text(tr('confirm', lang)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _onAction('rejectWin'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: Text(tr('reject', lang)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeOverlay(
      TableState state, int mySeat, Lang lang) {
    final proposal = state.pendingExchange!;
    final isTarget = proposal.toSeat == mySeat;

    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEE1A3A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.greenAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${state.nicknames[proposal.fromSeat]} → '
              '${state.nicknames[proposal.toSeat]}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${proposal.amount}${tr("points", lang)}',
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            if (isTarget) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _onAction('confirmExchange'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                    child: Text(tr('confirm', lang)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _onAction('rejectExchange'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: Text(tr('reject', lang)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
