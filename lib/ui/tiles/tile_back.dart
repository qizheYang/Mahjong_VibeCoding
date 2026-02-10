import 'package:flutter/material.dart';
import 'tile_size.dart';

/// Renders a face-down mahjong tile using the real back image.
class TileBack extends StatelessWidget {
  final TileSize size;

  const TileBack({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 1,
            offset: const Offset(0.5, 0.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size.borderRadius),
        child: Image.asset(
          'assets/tiles/back.png',
          width: size.width,
          height: size.height,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
