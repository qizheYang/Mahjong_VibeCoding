import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/state/player_state.dart';
import '../tiles/tile_size.dart';
import 'hand_display.dart';
import 'discard_pool.dart';
import 'meld_display.dart';

/// A complete player area: hand, discards, and melds.
class PlayerArea extends StatelessWidget {
  final PlayerState player;
  final bool isHuman;
  final TileSize handTileSize;
  final TileSize discardTileSize;
  final Tile? selectedTile;
  final ValueChanged<Tile>? onTileTap;

  const PlayerArea({
    super.key,
    required this.player,
    this.isHuman = false,
    required this.handTileSize,
    required this.discardTileSize,
    this.selectedTile,
    this.onTileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Discard pool
        DiscardPool(
          discards: player.discards,
          tileSize: discardTileSize,
          riichiDiscardIndex: player.riichiDiscardIndex,
        ),
        const SizedBox(height: 8),
        // Hand + Melds row
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HandDisplay(
              tiles: player.hand,
              faceUp: isHuman,
              tileSize: handTileSize,
              selectedTile: selectedTile,
              justDrew: isHuman ? player.justDrew : null,
              onTileTap: isHuman ? onTileTap : null,
            ),
            if (player.melds.isNotEmpty) ...[
              SizedBox(width: handTileSize.width * 0.3),
              MeldDisplay(
                melds: player.melds,
                tileSize: discardTileSize,
              ),
            ],
          ],
        ),
        // Riichi indicator
        if (player.isRiichi)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 40,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
