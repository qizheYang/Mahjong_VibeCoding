import 'package:flutter/material.dart';

import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays the wall as a compact indicator showing remaining tile count.
/// Uses a simplified 4-sided representation.
class WallDisplay extends StatelessWidget {
  final int wallRemaining;
  final int deadWallCount;

  const WallDisplay({
    super.key,
    required this.wallRemaining,
    required this.deadWallCount,
  });

  @override
  Widget build(BuildContext context) {
    // Show a compact wall representation
    // Total live stacks = ceil(wallRemaining / 2)
    // Distribute across 4 sides
    final totalStacks = (wallRemaining + 1) ~/ 2;
    final stacksPerSide = (totalStacks / 4).ceil().clamp(0, 17);

    const stackSize = TileSize(width: 8, height: 11);
    const gap = 1.0;

    final sideWidth = stacksPerSide * (stackSize.width + gap);

    return SizedBox(
      width: sideWidth + 40,
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left indicator
          _wallSideCompact(stacksPerSide, stackSize, gap),
          const SizedBox(width: 8),
          // Count text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x40000000),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$wallRemaining',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Right indicator
          _wallSideCompact(stacksPerSide, stackSize, gap),
        ],
      ),
    );
  }

  Widget _wallSideCompact(int stacks, TileSize size, double gap) {
    if (stacks <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stacks.clamp(0, 8), // show max 8 per side for compactness
        (_) => Padding(
          padding: EdgeInsets.symmetric(horizontal: gap / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TileBack(size: size),
              const SizedBox(height: 1),
              TileBack(size: size),
            ],
          ),
        ),
      ),
    );
  }
}
