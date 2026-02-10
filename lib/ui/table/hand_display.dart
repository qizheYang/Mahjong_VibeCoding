import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/tile/tile_sort.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays a player's hand tiles.
/// Face-up and interactive for the human player, face-down for opponents.
class HandDisplay extends StatelessWidget {
  final List<Tile> tiles;
  final bool faceUp;
  final TileSize tileSize;
  final Tile? selectedTile;
  final Tile? justDrew; // drawn tile shown with a gap
  final ValueChanged<Tile>? onTileTap;

  /// Set of tile IDs to highlight (for call-mode multi-select).
  final Set<int>? highlightedTileIds;

  const HandDisplay({
    super.key,
    required this.tiles,
    this.faceUp = false,
    required this.tileSize,
    this.selectedTile,
    this.justDrew,
    this.onTileTap,
    this.highlightedTileIds,
  });

  @override
  Widget build(BuildContext context) {
    if (!faceUp) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          tiles.length,
          (i) => Padding(
            padding: EdgeInsets.symmetric(horizontal: tileSize.spacing / 2),
            child: TileBack(size: tileSize),
          ),
        ),
      );
    }

    // Sort hand, but keep the just-drawn tile at the end with a gap
    final sorted = TileSort.sort(tiles);
    List<Tile> mainHand;
    Tile? drawnTile;

    if (justDrew != null && sorted.contains(justDrew!)) {
      mainHand = List.from(sorted);
      mainHand.remove(justDrew!);
      mainHand = TileSort.sort(mainHand);
      drawnTile = justDrew;
    } else {
      mainHand = sorted;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main hand tiles
        ...mainHand.map((tile) => Padding(
              padding: EdgeInsets.symmetric(horizontal: tileSize.spacing / 2),
              child: TileWidget(
                tile: tile,
                size: tileSize,
                isSelected: tile == selectedTile ||
                    (highlightedTileIds?.contains(tile.id) ?? false),
                onTap: onTileTap != null ? () => onTileTap!(tile) : null,
              ),
            )),
        // Gap + drawn tile
        if (drawnTile != null) ...[
          SizedBox(width: tileSize.width * 0.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tileSize.spacing / 2),
            child: TileWidget(
              tile: drawnTile,
              size: tileSize,
              isSelected: drawnTile == selectedTile ||
                  (highlightedTileIds?.contains(drawnTile.id) ?? false),
              onTap: onTileTap != null ? () => onTileTap!(drawnTile!) : null,
            ),
          ),
        ],
      ],
    );
  }
}
