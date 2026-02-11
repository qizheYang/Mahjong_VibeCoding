import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/tile/tile.dart';
import '../../i18n/strings.dart';
import '../../models/table_state.dart';
import '../../models/table_action.dart';
import '../../providers/multiplayer_provider.dart';
import '../table/multiplayer_table_view.dart';
import '../tiles/tile_widget.dart';
import '../hud/table_action_bar.dart';
import '../dialogs/win_declaration_dialog.dart';
import '../dialogs/exchange_dialog.dart';
import '../dialogs/objection_banner.dart';
import '../dialogs/suit_selection_overlay.dart';

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

  /// Timer for auto-draw countdown.
  Timer? _autoDrawTimer;

  /// Periodic timer for updating the countdown display.
  Timer? _countdownTicker;

  /// Whether the auto-draw prompt is showing.
  bool _showDrawPrompt = false;
  bool _drawPromptCanPon = false;
  bool _drawPromptCanChi = false;

  /// Seconds remaining before auto-draw fires.
  int _drawCountdown = 0;

  /// Whether we already scheduled the prompt for the current turn.
  bool _drawPromptScheduled = false;

  /// Whether the pon/kan call prompt is showing for non-current-turn player.
  bool _showPonPrompt = false;
  bool _ponHoldSent = false;
  bool _ponPromptScheduled = false;

  /// Tracks the last action log length to detect new actions.
  int _lastActionLogLength = 0;

  @override
  void dispose() {
    _kanTimer?.cancel();
    _autoDrawTimer?.cancel();
    _countdownTicker?.cancel();
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
    final autoFlower = ref.watch(autoFlowerProvider);

    // Watch hold state for auto-draw pausing
    final holdSeat = ref.watch(holdProvider);

    // Auto-draw: when it's my turn and I haven't drawn yet,
    // show a 5-second countdown prompt. Player can hit "Draw" to skip.
    // If another player called hold, pause the countdown.
    if (tableState != null && autoDraw && _callMode == null) {
      final mySeatIdx = conn.mySeat ?? 0;
      if (tableState.currentTurn == mySeatIdx &&
          !tableState.hasDrawnThisTurn) {
        if (holdSeat != null) {
          // Someone called hold — pause timer but keep prompt visible
          if (_autoDrawTimer != null) {
            _autoDrawTimer!.cancel();
            _autoDrawTimer = null;
            _countdownTicker?.cancel();
            _countdownTicker = null;
          }
        } else if (!_showDrawPrompt && !_drawPromptScheduled) {
          // Start fresh countdown
          _drawPromptScheduled = true;
          final ponOk = _canPon(tableState, mySeatIdx);
          final chiOk = _canChi(tableState, mySeatIdx);
          _startDrawCountdown();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _showDrawPrompt = true;
              _drawPromptCanPon = ponOk;
              _drawPromptCanChi = chiOk;
            });
          });
        } else if (_showDrawPrompt &&
            _autoDrawTimer == null &&
            _drawPromptScheduled) {
          // Hold was just released — restart countdown
          _startDrawCountdown();
        }
      } else {
        _drawPromptScheduled = false;
        _dismissDrawPrompt();
      }
    } else {
      _drawPromptScheduled = false;
      _dismissDrawPrompt();
    }

    // Pon/kan prompt for non-current-turn players:
    // When someone discards a tile I can pon, show Wait/Pon/Skip buttons.
    if (tableState != null && _callMode == null && !_showDrawPrompt) {
      final mySeatIdx = conn.mySeat ?? 0;
      if (tableState.currentTurn != mySeatIdx &&
          !tableState.hasDrawnThisTurn &&
          tableState.lastDiscardedTileId != null &&
          _canPon(tableState, mySeatIdx)) {
        if (!_showPonPrompt && !_ponPromptScheduled) {
          _ponPromptScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _showPonPrompt = true;
              _ponHoldSent = false;
            });
          });
        }
      } else {
        _ponPromptScheduled = false;
        _showPonPrompt = false;
        _ponHoldSent = false;
      }
    } else {
      _ponPromptScheduled = false;
      _showPonPrompt = false;
      _ponHoldSent = false;
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

    // Auto-flower: when I just drew a flower tile, auto 补花
    if (tableState != null && autoFlower && tableState.config.hasFlowers) {
      final mySeatIdx = conn.mySeat ?? 0;
      final seat = tableState.seats[mySeatIdx];
      if (seat.handTileIds != null) {
        final flowerInHand = seat.handTileIds!
            .where((id) => tableState.config.isFlowerTile(id))
            .toList();
        if (flowerInHand.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(multiplayerProvider.notifier)
                .sendAction(TableAction.drawFlower(flowerInHand.first));
          });
        }
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

    // Only show red dora tile faces in Riichi mode
    TileWidget.showRedDora = tableState.config.isRiichi;

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
                  autoFlower: autoFlower,
                  onAutoDrawChanged: (v) =>
                      ref.read(autoDrawProvider.notifier).state = v,
                  onAutoDiscardChanged: (v) =>
                      ref.read(autoDiscardProvider.notifier).state = v,
                  onAutoFlowerChanged: (v) =>
                      ref.read(autoFlowerProvider.notifier).state = v,
                ),

                // Sichuan suit selection overlay (缺一门)
                if (tableState.config.isSichuan &&
                    tableState.gameStarted &&
                    tableState.seats
                        .any((s) => s.missingSuit == null))
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 80, // leave room for hand tiles
                    child: SuitSelectionOverlay(
                      lang: lang,
                      allMissingSuits: tableState.seats
                          .map((s) => s.missingSuit)
                          .toList(),
                      nicknames: tableState.nicknames,
                      mySeat: mySeat,
                      alreadyChosen:
                          tableState.seats[mySeat].missingSuit != null,
                      onChoose: (suit) {
                        ref
                            .read(multiplayerProvider.notifier)
                            .sendAction(
                                TableAction.chooseMissingSuit(suit));
                      },
                    ),
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

          // Draw/pon prompt or action bar at the bottom
          if (_showDrawPrompt)
            _buildDrawPrompt(lang, holdSeat)
          else if (_showPonPrompt)
            _buildPonPrompt(lang)
          else
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
    final config = tableState?.config;
    final hasDora = config?.hasDora ?? false;
    final noKanDora = config?.noKanDora ?? false;

    _kanTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      final mp = ref.read(multiplayerProvider.notifier);
      // Only auto reveal dora for Riichi mode, skip if noKanDora is set
      if (hasDora && !noKanDora) {
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
        _dismissDrawPrompt();
        _drawPromptScheduled = false;
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

  // ─── Call availability checks ────────────────────────────

  /// Whether I can pon the last discard (2+ tiles of same kind in hand).
  bool _canPon(TableState state, int mySeat) {
    final discardId = state.lastDiscardedTileId;
    final discardBy = state.lastDiscardedBy;
    if (discardId == null || discardBy == null || discardBy == mySeat) {
      return false;
    }
    final handIds = state.seats[mySeat].handTileIds;
    if (handIds == null) return false;
    final discardKind = discardId ~/ 4;
    return handIds.where((id) => id ~/ 4 == discardKind).length >= 2;
  }

  /// Whether I can chi the last discard (sequence possible, prev player only).
  bool _canChi(TableState state, int mySeat) {
    if (state.config.isSichuan || state.config.isSuzhou) return false;
    final discardId = state.lastDiscardedTileId;
    final discardBy = state.lastDiscardedBy;
    if (discardId == null || discardBy == null) return false;
    if (discardBy != (mySeat - 1 + 4) % 4) return false;
    final handIds = state.seats[mySeat].handTileIds;
    if (handIds == null) return false;
    final discardKind = discardId ~/ 4;
    if (discardKind >= 27) return false; // can't chi honors
    final suitOffset = (discardKind ~/ 9) * 9;
    final num = discardKind % 9;
    final handKinds = handIds.map((id) => id ~/ 4).toSet();
    // num-2, num-1, num
    if (num >= 2 &&
        handKinds.contains(suitOffset + num - 2) &&
        handKinds.contains(suitOffset + num - 1)) {
      return true;
    }
    // num-1, num, num+1
    if (num >= 1 &&
        num <= 7 &&
        handKinds.contains(suitOffset + num - 1) &&
        handKinds.contains(suitOffset + num + 1)) {
      return true;
    }
    // num, num+1, num+2
    if (num <= 6 &&
        handKinds.contains(suitOffset + num + 1) &&
        handKinds.contains(suitOffset + num + 2)) {
      return true;
    }
    return false;
  }

  void _dismissDrawPrompt() {
    _autoDrawTimer?.cancel();
    _autoDrawTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    _showDrawPrompt = false;
    _drawPromptCanPon = false;
    _drawPromptCanChi = false;
  }

  void _drawNow() {
    _dismissDrawPrompt();
    _drawPromptScheduled = false;
    setState(() {});
    ref.read(multiplayerProvider.notifier).sendAction(TableAction.draw());
  }

  void _startDrawCountdown() {
    _autoDrawTimer?.cancel();
    _countdownTicker?.cancel();
    _drawCountdown = 5;
    _autoDrawTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _dismissDrawPrompt();
      _drawPromptScheduled = false;
      setState(() {});
      ref.read(multiplayerProvider.notifier).sendAction(TableAction.draw());
    });
    _countdownTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() => _drawCountdown = (_drawCountdown - 1).clamp(0, 5));
      },
    );
  }

  void _skipPonPrompt() {
    if (_ponHoldSent) {
      ref
          .read(multiplayerProvider.notifier)
          .sendAction(TableAction.releaseHold());
    }
    setState(() {
      _showPonPrompt = false;
      _ponPromptScheduled = false;
      _ponHoldSent = false;
    });
  }

  void _sendHold() {
    ref.read(multiplayerProvider.notifier).sendAction(TableAction.hold());
    setState(() => _ponHoldSent = true);
  }

  void _onCallModeFromPon(String mode) {
    if (_ponHoldSent) {
      ref
          .read(multiplayerProvider.notifier)
          .sendAction(TableAction.releaseHold());
    }
    setState(() {
      _showPonPrompt = false;
      _ponPromptScheduled = false;
      _ponHoldSent = false;
      _callMode = mode;
      _selectedTileIds.clear();
    });
  }

  void _onCallMode(String mode) {
    _dismissDrawPrompt();
    _drawPromptScheduled = false;
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

  /// Auto-draw prompt: shows countdown + Draw button + optional Pon/Chi.
  Widget _buildDrawPrompt(Lang lang, int? holdSeat) {
    final isPaused = holdSeat != null;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x001A1A3A), Color(0xEE1A1A3A)],
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _callPromptBtn(
              label: isPaused
                  ? '${tr('draw', lang)} ⏸'
                  : '${tr('draw', lang)} ($_drawCountdown)',
              colors: isPaused
                  ? const [Color(0xFF5A5A6A), Color(0xFF3A3A4A)]
                  : const [Color(0xFF1565C0), Color(0xFF0D47A1)],
              onTap: _drawNow,
            ),
            if (_drawPromptCanChi) ...[
              const SizedBox(width: 10),
              _callPromptBtn(
                label: tr('chi', lang),
                colors: const [Color(0xFF43A047), Color(0xFF2E7D32)],
                onTap: () => _onCallMode('chi'),
              ),
            ],
            if (_drawPromptCanPon) ...[
              const SizedBox(width: 10),
              _callPromptBtn(
                label: tr('pon', lang),
                colors: const [Color(0xFF00897B), Color(0xFF00695C)],
                onTap: () => _onCallMode('pon'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Pon prompt for non-current-turn players: Wait/Pon/Skip.
  Widget _buildPonPrompt(Lang lang) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x001A1A3A), Color(0xEE1A1A3A)],
        ),
      ),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _callPromptBtn(
              label: tr('skip', lang),
              colors: const [Color(0xFF5A5A6A), Color(0xFF3A3A4A)],
              onTap: _skipPonPrompt,
            ),
            if (!_ponHoldSent) ...[
              const SizedBox(width: 10),
              _callPromptBtn(
                label: tr('wait', lang),
                colors: const [Color(0xFFE65100), Color(0xFFBF360C)],
                onTap: _sendHold,
              ),
            ],
            const SizedBox(width: 10),
            _callPromptBtn(
              label: tr('pon', lang),
              colors: const [Color(0xFF00897B), Color(0xFF00695C)],
              onTap: () => _onCallModeFromPon('pon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callPromptBtn({
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────

  void _showWinDialog(Lang lang) {
    final tableState = ref.read(tableStateProvider);
    final config = tableState?.config;

    if (config != null && config.isSichuan) {
      // Sichuan: han 1-5, scoring is 2^han
      showDialog(
        context: context,
        builder: (ctx) => SichuanWinDialog(
          lang: lang,
          onDeclare: (isTsumo, han) {
            Navigator.of(ctx).pop();
            ref
                .read(multiplayerProvider.notifier)
                .sendAction(TableAction.declareWinSichuan(isTsumo, han));
          },
        ),
      );
    } else if (config != null && !config.isRiichi) {
      // Guobiao, Shanghai, Suzhou, etc.: direct point entry
      showDialog(
        context: context,
        builder: (ctx) => DirectWinDialog(
          lang: lang,
          onDeclare: (isTsumo, perPlayer) {
            Navigator.of(ctx).pop();
            ref
                .read(multiplayerProvider.notifier)
                .sendAction(TableAction.declareWinDirect(isTsumo, perPlayer));
          },
        ),
      );
    } else {
      // Riichi: han + fu
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
