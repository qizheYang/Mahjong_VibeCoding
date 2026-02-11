import 'package:flutter/material.dart';

import '../../engine/tile/tile.dart';
import '../../i18n/strings.dart';
import '../../models/table_state.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';
import '../tiles/tile_widget.dart';
import 'discard_pool.dart';
import 'hand_display.dart';
import 'meld_display.dart';
import 'wall_display.dart';

/// Main table view for the multiplayer free-form game.
///
/// Layout (no overlaps):
/// ```
///   [top opponent hand]
///   [left opp] [square table] [right opp]
///   [my hand]
/// ```
class MultiplayerTableView extends StatelessWidget {
  final TableState tableState;
  final int mySeat;
  final Set<int> selectedTileIds;
  final String? callMode;
  final ValueChanged<Tile>? onTileTap;
  final Lang lang;
  final bool autoDraw;
  final bool autoDiscard;
  final bool autoFlower;
  final ValueChanged<bool> onAutoDrawChanged;
  final ValueChanged<bool> onAutoDiscardChanged;
  final ValueChanged<bool> onAutoFlowerChanged;

  const MultiplayerTableView({
    super.key,
    required this.tableState,
    required this.mySeat,
    required this.selectedTileIds,
    this.callMode,
    this.onTileTap,
    required this.lang,
    required this.autoDraw,
    required this.autoDiscard,
    required this.autoFlower,
    required this.onAutoDrawChanged,
    required this.onAutoDiscardChanged,
    required this.onAutoFlowerChanged,
  });

  int _relativePosition(int seatIndex) => (seatIndex - mySeat + 4) % 4;
  int _absoluteSeat(int relativePos) => (relativePos + mySeat) % 4;

  @override
  Widget build(BuildContext context) {
    final handSize = TileSize.forHand(context);
    final discardSize = TileSize.small(context);
    final opponentSize = TileSize.tiny(context);

    return Column(
      children: [
        // Top opponent hand
        SizedBox(
          height: opponentSize.height + 12,
          child: Center(
            child: _buildOpponentRow(
                _absoluteSeat(2), opponentSize, discardSize),
          ),
        ),

        // Middle: left opponent | square table | right opponent
        Expanded(
          child: Row(
            children: [
              // Left opponent (rotated, draws bottom-to-top)
              SizedBox(
                width: opponentSize.height + 12,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: _buildOpponentRow(
                        _absoluteSeat(3), opponentSize, discardSize),
                  ),
                ),
              ),

              // Square table in center
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: _buildTable(discardSize),
                  ),
                ),
              ),

              // Right opponent (rotated)
              SizedBox(
                width: opponentSize.height + 12,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: _buildOpponentRow(
                        _absoluteSeat(1), opponentSize, discardSize),
                  ),
                ),
              ),
            ],
          ),
        ),

        // My hand at bottom
        SizedBox(
          height: handSize.height + 16,
          child: Center(
            child: _buildMyRow(handSize, discardSize),
          ),
        ),
      ],
    );
  }

  // ─── Square table (wall + discards + compass) ─────────────

  Widget _buildTable(TileSize ds) {
    final poolWidth = 6 * (ds.width + ds.spacing);

    return WallDisplay(
      wallRemaining: tableState.wallRemaining,
      deadWallCount: tableState.deadWallCount,
      doraIndicators: tableState.doraIndicators,
      doraRevealed: tableState.doraRevealed,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _wrappedDiscardPool(
                _absoluteSeat(2), ds, poolWidth, quarterTurns: 2),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _wrappedDiscardPool(
                    _absoluteSeat(3), ds, poolWidth, quarterTurns: 1),
                const SizedBox(width: 2),
                _buildCompass(),
                const SizedBox(width: 2),
                _wrappedDiscardPool(
                    _absoluteSeat(1), ds, poolWidth, quarterTurns: 3),
              ],
            ),
            const SizedBox(height: 2),
            _wrappedDiscardPool(_absoluteSeat(0), ds, poolWidth),
          ],
        ),
      ),
    );
  }

  Widget _wrappedDiscardPool(int seatIndex, TileSize ds, double poolWidth,
      {int quarterTurns = 0}) {
    final seat = tableState.seats[seatIndex];
    final discardTiles = seat.discards.map((d) => Tile(d.tileId)).toList();
    final riichiIdx = seat.discards.indexWhere((d) => d.isRiichiDiscard);
    final minRowH = ds.height + ds.spacing;

    Widget pool = ConstrainedBox(
      constraints: BoxConstraints(minWidth: poolWidth, minHeight: minRowH),
      child: DiscardPool(
        discards: discardTiles,
        tileSize: ds,
        riichiDiscardIndex: riichiIdx >= 0 ? riichiIdx : null,
      ),
    );

    if (quarterTurns != 0) {
      pool = RotatedBox(quarterTurns: quarterTurns, child: pool);
    }
    return pool;
  }

  // ─── Compass ───────────────────────────────────────────────

  Widget _buildCompass() {
    final windNames = [
      tr('east', lang),
      tr('south', lang),
      tr('west', lang),
      tr('north', lang),
    ];
    final roundWindStr = windNames[tableState.roundWind];
    final roundNumStr = '${tableState.roundNumber + 1}';
    final tilesLeft = tableState.wallRemaining;
    final currentTurn = tableState.currentTurn;

    return Container(
      width: 114,
      height: 114,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0A),
        border: Border.all(color: const Color(0xFF3A5A3A), width: 1.5),
      ),
      child: Stack(
        children: [
          _currentTurnHighlight(_relativePosition(currentTurn)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$roundWindStr$roundNumStr局',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tr("remaining", lang)} $tilesLeft',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (tableState.honbaCount > 0)
                  Text(
                    '${tableState.honbaCount}${tr("honba", lang)}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                if (tableState.riichiSticksOnTable > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'x${tableState.riichiSticksOnTable}',
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _compassLabel(0),
          _compassLabel(1),
          _compassLabel(2),
          _compassLabel(3),
          if (tableState.baidaReferenceTileId != null)
            Positioned(
              bottom: 2,
              right: 2,
              child: _baidaIndicator(tableState.baidaReferenceTileId!),
            ),
        ],
      ),
    );
  }

  Widget _baidaIndicator(int refTileId) {
    final refTile = Tile(refTileId);
    // Wild card is the next tile in sequence from the reference
    final refKind = refTile.kind;
    int wildKind;
    if (refKind < 27) {
      // Number tile: wrap within suit (0-8 per suit)
      final suit = refKind ~/ 9;
      final num = refKind % 9;
      wildKind = suit * 9 + (num + 1) % 9;
    } else {
      // Honor tile: winds 27-30 wrap, dragons 31-33 wrap
      if (refKind < 31) {
        wildKind = 27 + (refKind - 27 + 1) % 4;
      } else {
        wildKind = 31 + (refKind - 31 + 1) % 3;
      }
    }
    final wildTile = Tile(wildKind * 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${tr("baida", lang)}: ',
            style: const TextStyle(color: Colors.amber, fontSize: 8),
          ),
          Text(
            wildTile.shortName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compassLabel(int relativePos) {
    final seatIndex = _absoluteSeat(relativePos);
    final windNames = [
      tr('east', lang),
      tr('south', lang),
      tr('west', lang),
      tr('north', lang),
    ];
    final seatWind = (seatIndex - tableState.dealerSeat + 4) % 4;
    final wind = windNames[seatWind];
    final score = tableState.scores[seatIndex];
    final isCurrent = seatIndex == tableState.currentTurn;
    final color = isCurrent ? Colors.amber : Colors.white54;
    final missingSuit = tableState.seats[seatIndex].missingSuit;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$wind $score',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (missingSuit != null && tableState.config.isSichuan)
          _missingSuitBadge(missingSuit),
      ],
    );

    switch (relativePos) {
      case 0:
        return Positioned(
          bottom: 2, left: 0, right: 0,
          child: Center(child: content),
        );
      case 2:
        return Positioned(
          top: 2, left: 0, right: 0,
          child: Center(child: content),
        );
      case 3:
        return Positioned(
          left: 2, top: 22, bottom: 22,
          child: Center(
              child: RotatedBox(quarterTurns: 1, child: content)),
        );
      case 1:
        return Positioned(
          right: 2, top: 22, bottom: 22,
          child: Center(
              child: RotatedBox(quarterTurns: 3, child: content)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _missingSuitBadge(int suit) {
    final suitLabels = [
      tr('suitMan', lang),
      tr('suitPin', lang),
      tr('suitSou', lang),
    ];
    final suitColors = [Colors.red, Colors.blue, Colors.green];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: suitColors[suit].withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '${tr("missingSuitPrefix", lang)}${suitLabels[suit]}',
        style: const TextStyle(color: Colors.white, fontSize: 7),
      ),
    );
  }

  Widget _currentTurnHighlight(int relativePos) {
    const glow = Color(0x40FFD54F);
    switch (relativePos) {
      case 0:
        return Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 18, color: glow));
      case 2:
        return Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 18, color: glow));
      case 3:
        return Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(width: 18, color: glow));
      case 1:
        return Positioned(
            right: 0, top: 0, bottom: 0,
            child: Container(width: 18, color: glow));
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Player rows ───────────────────────────────────────────

  Widget _buildOpponentRow(
      int seatIndex, TileSize handSize, TileSize meldSize) {
    final seat = tableState.seats[seatIndex];
    final hasTiles = seat.handTileIds != null && seat.handTileIds!.isNotEmpty;
    final melds = seat.melds.map((m) => m.toMeld()).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasTiles)
          HandDisplay(
            tiles: seat.handTiles!,
            faceUp: true,
            tileSize: handSize,
          )
        else
          ...List.generate(
            seat.handCount,
            (_) => Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: handSize.spacing / 2),
              child: TileBack(size: handSize),
            ),
          ),
        if (melds.isNotEmpty) ...[
          SizedBox(width: handSize.width * 0.3),
          MeldDisplay(melds: melds, tileSize: meldSize),
        ],
        if (seat.flowerTileIds.isNotEmpty) ...[
          SizedBox(width: handSize.width * 0.3),
          _flowerDisplay(seat.flowerTiles, meldSize),
        ],
      ],
    );
  }

  Widget _buildMyRow(TileSize handSize, TileSize meldSize) {
    final seat = tableState.seats[mySeat];
    final handTiles = seat.handTiles ?? [];
    final melds = seat.melds.map((m) => m.toMeld()).toList();

    Tile? selectedTile;
    if (selectedTileIds.length == 1 && callMode == null) {
      selectedTile = Tile(selectedTileIds.first);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Auto toggles to the left of hand
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _autoToggle(tr('autoDraw', lang), autoDraw, onAutoDrawChanged),
            const SizedBox(height: 2),
            _autoToggle(
                tr('autoDiscard', lang), autoDiscard, onAutoDiscardChanged),
            if (tableState.config.hasFlowers) ...[
              const SizedBox(height: 2),
              _autoToggle(
                  tr('autoFlower', lang), autoFlower, onAutoFlowerChanged),
            ],
          ],
        ),
        const SizedBox(width: 6),
        HandDisplay(
          tiles: handTiles,
          faceUp: true,
          tileSize: handSize,
          selectedTile: selectedTile,
          justDrew: seat.justDrew,
          onTileTap: onTileTap,
          highlightedTileIds: callMode != null ? selectedTileIds : null,
        ),
        if (melds.isNotEmpty) ...[
          SizedBox(width: handSize.width * 0.3),
          MeldDisplay(melds: melds, tileSize: meldSize),
        ],
        if (seat.flowerTileIds.isNotEmpty) ...[
          SizedBox(width: handSize.width * 0.3),
          _flowerDisplay(seat.flowerTiles, meldSize),
        ],
      ],
    );
  }

  /// Render face-up flower tiles next to melds.
  Widget _flowerDisplay(List<Tile> flowers, TileSize size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: flowers
          .map((t) => Padding(
                padding: EdgeInsets.symmetric(horizontal: size.spacing / 2),
                child: TileWidget(tile: t, size: size),
              ))
          .toList(),
    );
  }

  Widget _autoToggle(
      String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: value
              ? Colors.amber.withValues(alpha: 0.8)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: value ? Colors.black : Colors.white60,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
