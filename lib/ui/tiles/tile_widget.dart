import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/tile/tile_type.dart';
import '../theme/tile_colors.dart';
import 'tile_size.dart';

/// Renders a single mahjong tile face-up.
class TileWidget extends StatelessWidget {
  final Tile tile;
  final TileSize size;
  final bool isSelected;
  final bool isSideways; // for riichi discard indicator
  final VoidCallback? onTap;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    this.isSelected = false,
    this.isSideways = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = TileColors.tileLabel(tile.type, tile.number);
    final kanji = TileColors.suitKanji(tile.type);
    final textColor = tile.type == TileType.dragon
        ? TileColors.dragonColor(tile.number)
        : TileColors.textColor(tile.type);
    final bgColor = tile.isRedDora ? TileColors.redDoraBg : TileColors.tileFace;

    Widget tileWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: isSelected ? TileColors.tileSelected : bgColor,
          borderRadius: BorderRadius.circular(size.borderRadius),
          border: Border.all(
            color: TileColors.tileBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (tile.type == TileType.dragon && tile.number == 1)
              // Haku: empty white tile with border
              Container(
                width: size.width * 0.5,
                height: size.width * 0.5,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: size.fontSize,
                  fontWeight: FontWeight.bold,
                  color: tile.isRedDora ? Colors.red : textColor,
                  height: 1.1,
                ),
              ),
              if (kanji.isNotEmpty)
                Text(
                  kanji,
                  style: TextStyle(
                    fontSize: size.smallFontSize,
                    color: tile.isRedDora ? Colors.red : textColor,
                    height: 1.0,
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (isSideways) {
      tileWidget = Transform.rotate(
        angle: 1.5708, // 90 degrees
        child: tileWidget,
      );
    }

    return tileWidget;
  }
}
