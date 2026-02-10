import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/state/player_state.dart';
import '../../engine/state/round_state.dart';
import '../../engine/state/game_state.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';
import '../tiles/tile_widget.dart';
import 'discard_pool.dart';
import 'hand_display.dart';
import 'meld_display.dart';

/// Tenhou-style table view.
/// Center: compass + 4 discard pools. Edges: player hands.
class TableView extends StatelessWidget {
  final GameState gameState;
  final Tile? selectedTile;
  final ValueChanged<Tile>? onTileTap;

  const TableView({
    super.key,
    required this.gameState,
    this.selectedTile,
    this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    final round = gameState.currentRound;
    if (round == null) return const SizedBox.shrink();

    final handSize = TileSize.forHand(context);
    final discardSize = TileSize.small(context);
    final opponentSize = TileSize.tiny(context);

    return Stack(
      children: [
        // Center area: compass + 4 discard pools + dora
        Center(
          child: _buildCenterArea(round, discardSize),
        ),

        // Top opponent (seat 2)
        Positioned(
          top: 4,
          left: 0,
          right: 0,
          child: Center(
            child: _buildOpponentRow(round.players[2], opponentSize, discardSize),
          ),
        ),

        // Left opponent (seat 3) — rotated 90° CW
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 1,
              child: _buildOpponentRow(round.players[3], opponentSize, discardSize),
            ),
          ),
        ),

        // Right opponent (seat 1) — rotated 90° CCW
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: _buildOpponentRow(round.players[1], opponentSize, discardSize),
            ),
          ),
        ),

        // Human player hand + melds (bottom)
        Positioned(
          bottom: 52,
          left: 0,
          right: 0,
          child: Center(
            child: _buildHumanRow(round.players[0], handSize, discardSize),
          ),
        ),
      ],
    );
  }

  // ─── Center area ───────────────────────────────────────────

  Widget _buildCenterArea(RoundState round, TileSize ds) {
    const doraTileSize = TileSize(width: 18, height: 25);
    final poolWidth = 6 * (ds.width + ds.spacing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Seat 2 discards (rotated 180°)
        _wrappedPool(round.players[2], ds, poolWidth, quarterTurns: 2),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seat 3 discards (rotated 90° CW → first row closest to compass)
            _wrappedPool(round.players[3], ds, poolWidth, quarterTurns: 1),
            const SizedBox(width: 2),
            _buildCompass(round),
            const SizedBox(width: 2),
            // Seat 1 discards (rotated 270° CW → first row closest to compass)
            _wrappedPool(round.players[1], ds, poolWidth, quarterTurns: 3),
          ],
        ),
        const SizedBox(height: 2),
        // Seat 0 discards (normal)
        _wrappedPool(round.players[0], ds, poolWidth),
        const SizedBox(height: 6),
        // Dora indicators
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...round.wall.doraIndicators.map((tile) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: TileWidget(tile: tile, size: doraTileSize),
                )),
            const SizedBox(width: 6),
            ...List.generate(
              round.wall.doraRevealedCount,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: TileBack(size: doraTileSize),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Discard pool wrapped in a ConstrainedBox so the center area
  /// keeps a stable size even when pools are empty.
  Widget _wrappedPool(PlayerState player, TileSize ds, double poolWidth, {int quarterTurns = 0}) {
    final minRowH = ds.height + ds.spacing;

    Widget pool = ConstrainedBox(
      constraints: BoxConstraints(minWidth: poolWidth, minHeight: minRowH),
      child: DiscardPool(
        discards: player.discards,
        tileSize: ds,
        riichiDiscardIndex: player.riichiDiscardIndex,
      ),
    );

    if (quarterTurns != 0) {
      pool = RotatedBox(quarterTurns: quarterTurns, child: pool);
    }

    return pool;
  }

  // ─── Compass ───────────────────────────────────────────────

  Widget _buildCompass(RoundState round) {
    final windNames = ['東', '南', '西', '北'];
    final roundWindStr = windNames[round.roundWind];
    final roundNumStr = '${round.roundNumber + 1}';
    final tilesLeft = round.wall.remaining;
    final currentTurn = round.currentTurn;

    return Container(
      width: 114,
      height: 114,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1A0A),
        border: Border.all(color: const Color(0xFF3A5A3A), width: 1.5),
      ),
      child: Stack(
        children: [
          // Highlight current player's side
          _currentTurnHighlight(currentTurn),

          // Center: round info
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
                  '残 $tilesLeft',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (gameState.honbaCount > 0)
                  Text(
                    '${gameState.honbaCount}本場',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                if (gameState.riichiSticksOnTable > 0)
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
                        '×${gameState.riichiSticksOnTable}',
                        style: const TextStyle(color: Colors.amber, fontSize: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Bottom (seat 0 = You)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: _compassSide(0, round, windNames, currentTurn),
          ),
          // Top (seat 2)
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: _compassSide(2, round, windNames, currentTurn),
          ),
          // Left (seat 3)
          Positioned(
            left: 2,
            top: 22,
            bottom: 22,
            child: _compassSideVertical(3, round, windNames, currentTurn, alignRight: false),
          ),
          // Right (seat 1)
          Positioned(
            right: 2,
            top: 22,
            bottom: 22,
            child: _compassSideVertical(1, round, windNames, currentTurn, alignRight: true),
          ),
        ],
      ),
    );
  }

  /// Subtle highlight bar on the current player's side of the compass.
  Widget _currentTurnHighlight(int currentTurn) {
    const glow = Color(0x40FFD54F);
    switch (currentTurn) {
      case 0:
        return Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(height: 18, color: glow),
        );
      case 2:
        return Positioned(
          top: 0, left: 0, right: 0,
          child: Container(height: 18, color: glow),
        );
      case 3:
        return Positioned(
          left: 0, top: 0, bottom: 0,
          child: Container(width: 18, color: glow),
        );
      case 1:
        return Positioned(
          right: 0, top: 0, bottom: 0,
          child: Container(width: 18, color: glow),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Horizontal compass label (top / bottom).
  Widget _compassSide(int seat, RoundState round, List<String> windNames, int currentTurn) {
    final wind = windNames[round.players[seat].seatWind];
    final score = gameState.scores[seat];
    final isCurrent = seat == currentTurn;
    final color = isCurrent ? Colors.amber : Colors.white54;

    return Center(
      child: Text(
        '$wind  $score',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// Vertical compass label (left / right).
  Widget _compassSideVertical(int seat, RoundState round, List<String> windNames, int currentTurn,
      {required bool alignRight}) {
    final wind = windNames[round.players[seat].seatWind];
    final score = gameState.scores[seat];
    final isCurrent = seat == currentTurn;
    final color = isCurrent ? Colors.amber : Colors.white54;

    return Center(
      child: RotatedBox(
        quarterTurns: alignRight ? 3 : 1,
        child: Text(
          '$wind $score',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ─── Player rows ───────────────────────────────────────────

  /// Opponent hand (face-down) + melds + riichi indicator.
  Widget _buildOpponentRow(PlayerState player, TileSize handSize, TileSize meldSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Face-down hand
            ...List.generate(
              player.hand.length,
              (_) => Padding(
                padding: EdgeInsets.symmetric(horizontal: handSize.spacing / 2),
                child: TileBack(size: handSize),
              ),
            ),
            // Melds
            if (player.melds.isNotEmpty) ...[
              SizedBox(width: handSize.width * 0.3),
              MeldDisplay(melds: player.melds, tileSize: meldSize),
            ],
          ],
        ),
        // Riichi stick indicator
        if (player.isRiichi)
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

  /// Human hand (face-up, interactive) + melds + riichi indicator.
  Widget _buildHumanRow(PlayerState player, TileSize handSize, TileSize meldSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player.isRiichi)
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
            HandDisplay(
              tiles: player.hand,
              faceUp: true,
              tileSize: handSize,
              selectedTile: selectedTile,
              justDrew: player.justDrew,
              onTileTap: onTileTap,
            ),
            if (player.melds.isNotEmpty) ...[
              SizedBox(width: handSize.width * 0.3),
              MeldDisplay(melds: player.melds, tileSize: meldSize),
            ],
          ],
        ),
      ],
    );
  }
}
