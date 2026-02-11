import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/tile/tile_type.dart';
import 'tile_size.dart';

/// Renders a single mahjong tile face-up using real tile graphics.
/// Flower tiles are rendered as colored text on white background.
class TileWidget extends StatelessWidget {
  /// Whether to show red dora tile faces (only relevant in Riichi mode).
  /// Set by the table view based on game config before building.
  static bool showRedDora = true;

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

  /// Standard flower asset names by index (0-7: 春夏秋冬梅兰竹菊).
  static const _flowerAssets = [
    'assets/tiles/flower_chun.png', // 春
    'assets/tiles/flower_xia.png', // 夏
    'assets/tiles/flower_qiu.png', // 秋
    'assets/tiles/flower_dong.png', // 冬
    'assets/tiles/flower_mei.png', // 梅
    'assets/tiles/flower_lan.png', // 兰
    'assets/tiles/flower_zhu.png', // 竹
    'assets/tiles/flower_ju.png', // 菊
  ];

  /// Map a Tile to its asset filename (null for text-rendered tiles).
  static String? tileAsset(Tile tile) {
    if (tile.isFlower) {
      final idx = tile.id - 136;
      if (idx < _flowerAssets.length) return _flowerAssets[idx];
      return null; // extra flowers (144-151) rendered as text
    }
    if (tile.isRedDora && showRedDora) {
      final suit = switch (tile.type) {
        TileType.man => 'm',
        TileType.pin => 'p',
        TileType.sou => 's',
        _ => 'm',
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
      case TileType.flower:
        return null;
    }
  }

  /// Flower tile text color by group.
  static Color _flowerColor(Tile tile) {
    final group = tile.flowerGroup;
    switch (group) {
      case 0:
        return const Color(0xFFE53935); // seasons: red
      case 1:
        return const Color(0xFF1E88E5); // plants: blue
      case 2:
        return const Color(0xFFFF6F00); // 百搭: orange
      case 3:
        return const Color(0xFF43A047); // suzhou specials: green
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = tileAsset(tile);

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
          child: asset != null
              ? Image.asset(
                  asset,
                  width: size.width,
                  height: size.height,
                  fit: BoxFit.fill,
                )
              : _buildFlowerTile(),
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

  Widget _buildFlowerTile() {
    final color = _flowerColor(tile);
    final label = tile.shortName;
    final isExtra = tile.id >= 144; // extra flowers: bracketed style
    final fontSize = size.width * (isExtra ? 0.42 : 0.55);
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isExtra ? Colors.grey.shade400 : Colors.grey.shade300,
          width: isExtra ? 1.5 : 0.5,
        ),
        borderRadius: isExtra ? BorderRadius.circular(size.borderRadius) : null,
      ),
      child: Center(
        child: Text(
          isExtra ? '[$label]' : label,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
