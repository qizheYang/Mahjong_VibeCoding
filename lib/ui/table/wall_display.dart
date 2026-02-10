import 'package:flutter/material.dart';

import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays the wall as 4 sides of face-down tile stacks forming a border
/// around the [child] widget. Each stack is 2 tiles high.
/// Tiles are distributed evenly across 4 sides.
class WallDisplay extends StatelessWidget {
  final int wallRemaining;
  final int deadWallCount;
  final Widget child;

  const WallDisplay({
    super.key,
    required this.wallRemaining,
    required this.deadWallCount,
    required this.child,
  });

  static const _stackSize = TileSize(width: 8, height: 11);
  static const _gap = 1.0;

  /// Thickness of the wall border (height of one 2-tile stack).
  double get _wallThickness => _stackSize.height * 2 + 1;

  @override
  Widget build(BuildContext context) {
    final totalStacks = (wallRemaining + 1) ~/ 2;
    final perSide = (totalStacks / 4).ceil().clamp(0, 17);
    final remainder = totalStacks - perSide * 3;
    final bottomStacks = remainder.clamp(0, 17);
    final wt = _wallThickness;

    return Stack(
      children: [
        // Child content padded to leave room for walls on all sides
        Padding(
          padding: EdgeInsets.all(wt + 2),
          child: child,
        ),

        // Top wall (full width)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _horizontalWall(perSide)),
        ),
        // Bottom wall (full width)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(child: _horizontalWall(bottomStacks)),
        ),
        // Left wall (between top and bottom walls)
        Positioned(
          left: 0,
          top: wt,
          bottom: wt,
          child: Center(child: _verticalWall(perSide)),
        ),
        // Right wall (between top and bottom walls)
        Positioned(
          right: 0,
          top: wt,
          bottom: wt,
          child: Center(child: _verticalWall(perSide)),
        ),
      ],
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
