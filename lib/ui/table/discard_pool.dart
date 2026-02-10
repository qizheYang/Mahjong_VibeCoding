import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_size.dart';

/// Displays a player's discarded tiles in a grid layout (牌河).
/// 6 tiles per row, 3 main rows. Overflow extends right of row 3.
/// Riichi discard shown sideways.
class DiscardPool extends StatelessWidget {
  final List<Tile> discards;
  final TileSize tileSize;
  final int? riichiDiscardIndex;
  final int tilesPerRow;

  const DiscardPool({
    super.key,
    required this.discards,
    required this.tileSize,
    this.riichiDiscardIndex,
    this.tilesPerRow = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (discards.isEmpty) return const SizedBox.shrink();

    // Split discards into rows of 6
    final rows = <List<int>>[];
    for (int i = 0; i < discards.length; i += tilesPerRow) {
      final end = (i + tilesPerRow).clamp(0, discards.length);
      rows.add(List.generate(end - i, (j) => i + j));
    }

    // Fixed row width = 6 normal tiles + spacing
    final rowWidth = tilesPerRow * (tileSize.width + tileSize.spacing);

    return SizedBox(
      width: rowWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map((indices) {
          return SizedBox(
            height: tileSize.height + tileSize.spacing,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: indices.map((i) {
                final isSideways = i == riichiDiscardIndex;
                return Padding(
                  padding: EdgeInsets.only(right: tileSize.spacing),
                  child: SizedBox(
                    width: isSideways ? tileSize.height : tileSize.width,
                    height: isSideways ? tileSize.width : tileSize.height,
                    child: Center(
                      child: TileWidget(
                        tile: discards[i],
                        size: tileSize,
                        isSideways: isSideways,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
