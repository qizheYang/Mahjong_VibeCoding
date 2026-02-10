import 'package:flutter/material.dart';

import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays the wall as 4 rows of face-down tile stacks surrounding the center.
/// Each stack is 2 tiles high. Tiles are distributed evenly across 4 sides.
class WallDisplay extends StatelessWidget {
  final int wallRemaining;
  final int deadWallCount;

  const WallDisplay({
    super.key,
    required this.wallRemaining,
    required this.deadWallCount,
  });

  static const _stackSize = TileSize(width: 8, height: 11);
  static const _gap = 1.0;

  @override
  Widget build(BuildContext context) {
    // Total stacks = ceil(remaining / 2), split across 4 sides
    final totalStacks = (wallRemaining + 1) ~/ 2;
    final perSide = (totalStacks / 4).ceil().clamp(0, 17);
    // Bottom gets the remainder
    final remainder = totalStacks - perSide * 3;
    final bottomStacks = remainder.clamp(0, 17);

    final sideWidth = perSide * (_stackSize.width + _gap);
    final sideHeight = perSide * (_stackSize.width + _gap);

    return SizedBox(
      width: sideWidth + 40,
      height: sideHeight + 40,
      child: Stack(
        children: [
          // Top wall
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Center(child: _horizontalWall(perSide)),
          ),
          // Bottom wall
          Positioned(
            bottom: 0,
            left: 20,
            right: 20,
            child: Center(child: _horizontalWall(bottomStacks)),
          ),
          // Left wall
          Positioned(
            left: 0,
            top: 20,
            bottom: 20,
            child: Center(child: _verticalWall(perSide)),
          ),
          // Right wall
          Positioned(
            right: 0,
            top: 20,
            bottom: 20,
            child: Center(child: _verticalWall(perSide)),
          ),
          // Center: remaining count
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x40000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$wallRemaining',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalWall(int stacks) {
    if (stacks <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stacks,
        (_) => Padding(
          padding: EdgeInsets.symmetric(horizontal: _gap / 2),
          child: _tileStack(),
        ),
      ),
    );
  }

  Widget _verticalWall(int stacks) {
    if (stacks <= 0) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        stacks,
        (_) => Padding(
          padding: EdgeInsets.symmetric(vertical: _gap / 2),
          child: RotatedBox(
            quarterTurns: 1,
            child: _tileStack(),
          ),
        ),
      ),
    );
  }

  Widget _tileStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TileBack(size: _stackSize),
        const SizedBox(height: 1),
        TileBack(size: _stackSize),
      ],
    );
  }
}
