import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/tile/tile_type.dart';
import 'tile_size.dart';

/// Renders a single mahjong tile face-up using real tile graphics.
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

  /// Map a Tile to its asset filename.
  static String tileAsset(Tile tile) {
    if (tile.isRedDora) {
      // Red fives: 0m, 0p, 0s
      final suit = switch (tile.type) {
        TileType.man => 'm',
        TileType.pin => 'p',
        TileType.sou => 's',
        _ => 'm', // shouldn't happen
      };
      return 'assets/tiles/0$suit.png';
    }
    switch (tile.type) {
      case TileType.man:
        return 'assets/tiles/${tile.number}m.png';
      case TileType.pin:
        return 'assets/tiles/${tile.number}p.png';
      case TileType.sou:
        return 'assets/tiles/${tile.number}s.png';
      case TileType.wind:
        return 'assets/tiles/${tile.number}z.png';
      case TileType.dragon:
        return 'assets/tiles/${tile.number + 4}z.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tileWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size.borderRadius),
          border: isSelected
              ? Border.all(color: Colors.amber, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size.borderRadius),
          child: Image.asset(
            tileAsset(tile),
            width: size.width,
            height: size.height,
            fit: BoxFit.fill,
          ),
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
