import 'package:flutter/material.dart';

import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays the wall as 4 sides of face-down tile stacks forming a border
/// around the [child] widget. All 68 stack positions (136 tiles / 2) are
/// rendered individually across 4 sides (17 per side). Stacks are consumed
/// from the draw-front end with a slide+fade animation.
class WallDisplay extends StatefulWidget {
  final int wallRemaining;
  final int deadWallCount;
  final Widget child;

  const WallDisplay({
    super.key,
    required this.wallRemaining,
    required this.deadWallCount,
    required this.child,
  });

  @override
  State<WallDisplay> createState() => _WallDisplayState();
}

class _WallDisplayState extends State<WallDisplay>
    with SingleTickerProviderStateMixin {
  static const _totalStacks = 68; // 136 tiles / 2
  static const _perSide = 17;
  static const _gap = 1.0;

  late AnimationController _drawAnim;

  /// Global stack index currently animating away (-1 = none).
  int _animStack = -1;

  /// true = animating top tile of a 2-tile stack (2 -> 1).
  /// false = animating the last tile of a stack (1 -> 0).
  bool _animTopOnly = false;

  @override
  void initState() {
    super.initState();
    _drawAnim = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _animStack = -1);
        }
      });
  }

  @override
  void didUpdateWidget(WallDisplay old) {
    super.didUpdateWidget(old);
    if (widget.wallRemaining < old.wallRemaining) {
      final oldActive = (old.wallRemaining + 1) ~/ 2;
      final oldFront = _totalStacks - oldActive;
      _animStack = oldFront;
      // Even count means top tile is drawn first (2 -> 1)
      _animTopOnly = old.wallRemaining.isEven;
      _drawAnim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drawAnim.dispose();
    super.dispose();
  }

  TileSize _wallTileSize(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final w = (screenW / 42).clamp(10.0, 18.0);
    return TileSize(width: w, height: w * 1.4);
  }

  @override
  Widget build(BuildContext context) {
    final ts = _wallTileSize(context);
    // Wall thickness = tile height + depth offset for 2-tile stacking
    final wt = ts.height + 4;

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(wt + 2),
          child: widget.child,
        ),

        // Top wall (indices 0-16, left to right)
        Positioned(
          top: 0,
          left: wt,
          right: wt,
          child: Center(child: _buildHSide(0, ts)),
        ),
        // Right wall (indices 17-33, top to bottom)
        Positioned(
          right: 0,
          top: wt,
          bottom: wt,
          child: Center(child: _buildVSide(1, ts)),
        ),
        // Bottom wall (indices 34-50, right to left)
        Positioned(
          bottom: 0,
          left: wt,
          right: wt,
          child: Center(child: _buildHSide(2, ts, reversed: true)),
        ),
        // Left wall (indices 51-67, bottom to top)
        Positioned(
          left: 0,
          top: wt,
          bottom: wt,
          child: Center(child: _buildVSide(3, ts, reversed: true)),
        ),
      ],
    );
  }

  Widget _buildHSide(int side, TileSize ts, {bool reversed = false}) {
    final start = side * _perSide;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_perSide, (i) {
        final idx = start + (reversed ? (_perSide - 1 - i) : i);
        return _stackWidget(idx, ts, vertical: false);
      }),
    );
  }

  Widget _buildVSide(int side, TileSize ts, {bool reversed = false}) {
    final start = side * _perSide;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_perSide, (i) {
        final idx = start + (reversed ? (_perSide - 1 - i) : i);
        return _stackWidget(idx, ts, vertical: true);
      }),
    );
  }

  /// How many tiles (0, 1, or 2) at global stack position [idx].
  int _tileCountAt(int idx) {
    final activeStacks = (widget.wallRemaining + 1) ~/ 2;
    final front = _totalStacks - activeStacks;
    if (idx < front) return 0;
    if (idx == front && widget.wallRemaining.isOdd) return 1;
    return 2;
  }

  Widget _stackWidget(int idx, TileSize ts, {required bool vertical}) {
    final stackW = ts.width + _gap;
    final stackH = ts.height + 4;
    final boxW = vertical ? stackH : stackW;
    final boxH = vertical ? stackW : stackH;

    int count = _tileCountAt(idx);
    final isAnimating = idx == _animStack && _drawAnim.isAnimating;

    // During animation, show one more tile than current count
    if (isAnimating) {
      count = _animTopOnly ? 2 : 1;
    }

    if (count == 0) {
      return SizedBox(width: boxW, height: boxH);
    }

    Widget stack = _tileStack(ts, count, isAnimating);
    if (vertical) {
      stack = RotatedBox(quarterTurns: 1, child: stack);
    }

    return SizedBox(
      width: boxW,
      height: boxH,
      child: Center(child: stack),
    );
  }

  Widget _tileStack(TileSize ts, int count, bool animating) {
    final hasTwo = count >= 2;
    final depthOffset = hasTwo ? 3.0 : 0.0;

    Widget bottomTile = TileBack(size: ts);
    Widget? topTile = hasTwo ? TileBack(size: ts) : null;

    if (animating) {
      if (_animTopOnly && topTile != null) {
        topTile = _animatedTile(ts);
      } else if (!_animTopOnly) {
        bottomTile = _animatedTile(ts);
      }
    }

    return SizedBox(
      width: ts.width,
      height: ts.height + depthOffset,
      child: Stack(
        children: [
          Positioned(bottom: 0, left: 0, child: bottomTile),
          if (topTile != null) Positioned(top: 0, left: 0, child: topTile),
        ],
      ),
    );
  }

  /// A tile that slides up and fades out.
  Widget _animatedTile(TileSize ts) {
    return AnimatedBuilder(
      animation: _drawAnim,
      builder: (context, child) {
        return Opacity(
          opacity: 1.0 - _drawAnim.value,
          child: Transform.translate(
            offset: Offset(0, -_drawAnim.value * ts.height * 0.6),
            child: child,
          ),
        );
      },
      child: TileBack(size: ts),
    );
  }
}
