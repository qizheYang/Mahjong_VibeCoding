import 'package:flutter/material.dart';
import '../theme/tile_colors.dart';
import 'tile_size.dart';

/// Renders a face-down mahjong tile.
class TileBack extends StatelessWidget {
  final TileSize size;

  const TileBack({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: TileColors.tileBack,
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
    );
  }
}
