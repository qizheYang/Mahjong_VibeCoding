import 'package:flutter/material.dart';

import '../../engine/tile/tile.dart';
import '../../i18n/strings.dart';
import '../../models/table_state.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';
import 'discard_pool.dart';
import 'hand_display.dart';
import 'meld_display.dart';
import 'wall_display.dart';

/// Main table view for the multiplayer free-form game.
class MultiplayerTableView extends StatelessWidget {
  final TableState tableState;
  final int mySeat;
  final Set<int> selectedTileIds;
  final String? callMode;
  final ValueChanged<Tile>? onTileTap;
  final Lang lang;

  const MultiplayerTableView({
    super.key,
    required this.tableState,
    required this.mySeat,
    required this.selectedTileIds,
    this.callMode,
    this.onTileTap,
    required this.lang,
  });

  /// Map absolute seat index to relative position (0=bottom, 1=right, 2=top, 3=left).
  int _relativePosition(int seatIndex) {
    return (seatIndex - mySeat + 4) % 4;
  }

  /// Map relative position back to absolute seat index.
  int _absoluteSeat(int relativePos) {
    return (relativePos + mySeat) % 4;
  }

  @override
  Widget build(BuildContext context) {
    final handSize = TileSize.forHand(context);
    final discardSize = TileSize.small(context);
    final opponentSize = TileSize.tiny(context);

    return Stack(
      children: [
        // Center area: wall + compass + 4 discard pools + dora
        Center(
          child: _buildCenterArea(discardSize),
        ),

        // Top opponent (relative pos 2)
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Center(
            child: _buildOpponentRow(_absoluteSeat(2), opponentSize, discardSize),
          ),
        ),

        // Left opponent (relative pos 3)
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: _buildOpponentRow(
                  _absoluteSeat(3), opponentSize, discardSize),
            ),
          ),
        ),

        // Right opponent (relative pos 1)
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: _buildOpponentRow(
                  _absoluteSeat(1), opponentSize, discardSize),
            ),
          ),
        ),

        // My hand + melds (bottom)
        Positioned(
          bottom: 52,
          left: 0,
          right: 0,
          child: Center(
            child: _buildMyRow(handSize, discardSize),
          ),
        ),
      ],
    );
  }

  // ─── Center area ───────────────────────────────────────────

  Widget _buildCenterArea(TileSize ds) {
    const doraTileSize = TileSize(width: 18, height: 25);
    final poolWidth = 6 * (ds.width + ds.spacing);

    // Wall forms a border around the center content
    return WallDisplay(
      wallRemaining: tableState.wallRemaining,
      deadWallCount: tableState.deadWallCount,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seat 2 (top) discards
          _wrappedDiscardPool(_absoluteSeat(2), ds, poolWidth,
              quarterTurns: 2),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _wrappedDiscardPool(_absoluteSeat(3), ds, poolWidth,
                  quarterTurns: 1),
              const SizedBox(width: 2),
              _buildCompass(),
              const SizedBox(width: 2),
              _wrappedDiscardPool(_absoluteSeat(1), ds, poolWidth,
                  quarterTurns: 3),
            ],
          ),
          const SizedBox(height: 2),
          _wrappedDiscardPool(_absoluteSeat(0), ds, poolWidth),
          const SizedBox(height: 6),

          // Dora indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tableState.doraIndicators.map((tile) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: TileWidget(tile: tile, size: doraTileSize),
                  )),
              // Unrevealed dora slots
              ...List.generate(
                5 - tableState.doraRevealed,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: TileBack(size: doraTileSize),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wrappedDiscardPool(int seatIndex, TileSize ds, double poolWidth,
      {int quarterTurns = 0}) {
    final seat = tableState.seats[seatIndex];
    final discardTiles = seat.discards.map((d) => Tile(d.tileId)).toList();
    final riichiIdx =
        seat.discards.indexWhere((d) => d.isRiichiDiscard);
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
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10),
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

          // Seat labels on compass edges
          _compassLabel(0), // bottom = me
          _compassLabel(1), // right
          _compassLabel(2), // top
          _compassLabel(3), // left
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
    // Seat wind based on dealer position
    final seatWind = (seatIndex - tableState.dealerSeat + 4) % 4;
    final wind = windNames[seatWind];
    final score = tableState.scores[seatIndex];
    final isCurrent = seatIndex == tableState.currentTurn;
    final color = isCurrent ? Colors.amber : Colors.white54;
    final text = Text(
      '$wind $score',
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
      ),
    );

    switch (relativePos) {
      case 0: // bottom
        return Positioned(
          bottom: 2,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                text,
              ],
            ),
          ),
        );
      case 2: // top
        return Positioned(
          top: 2,
          left: 0,
          right: 0,
          child: Center(child: text),
        );
      case 3: // left
        return Positioned(
          left: 2,
          top: 22,
          bottom: 22,
          child: Center(
            child: RotatedBox(quarterTurns: 1, child: text),
          ),
        );
      case 1: // right
        return Positioned(
          right: 2,
          top: 22,
          bottom: 22,
          child: Center(
            child: RotatedBox(quarterTurns: 3, child: text),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _currentTurnHighlight(int relativePos) {
    const glow = Color(0x40FFD54F);
    switch (relativePos) {
      case 0:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(height: 18, color: glow),
        );
      case 2:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(height: 18, color: glow),
        );
      case 3:
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 18, color: glow),
        );
      case 1:
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 18, color: glow),
        );
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTiles)
              // Revealed hand
              HandDisplay(
                tiles: seat.handTiles!,
                faceUp: true,
                tileSize: handSize,
              )
            else
              // Face-down hand
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
          ],
        ),
        if (seat.isRiichi)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMyRow(TileSize handSize, TileSize meldSize) {
    final seat = tableState.seats[mySeat];
    final handTiles = seat.handTiles ?? [];
    final melds = seat.melds.map((m) => m.toMeld()).toList();

    // Build selection set as Tiles for the HandDisplay
    Tile? selectedTile;
    if (selectedTileIds.length == 1 && callMode == null) {
      selectedTile = Tile(selectedTileIds.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seat.isRiichi)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Container(
              width: 30,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Hand tiles with call-mode multi-select
            _buildMyHand(handTiles, seat.justDrew, handSize, selectedTile),
            if (melds.isNotEmpty) ...[
              SizedBox(width: handSize.width * 0.3),
              MeldDisplay(melds: melds, tileSize: meldSize),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMyHand(
      List<Tile> tiles, Tile? justDrew, TileSize size, Tile? selectedTile) {
    // For call mode, highlight selected tiles differently
    return HandDisplay(
      tiles: tiles,
      faceUp: true,
      tileSize: size,
      selectedTile: selectedTile,
      justDrew: justDrew,
      onTileTap: onTileTap,
      highlightedTileIds: callMode != null ? selectedTileIds : null,
    );
  }
}
