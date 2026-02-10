import 'dart:math' show min;

import 'package:flutter/material.dart';

import '../../engine/tile/tile.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_size.dart';

/// Displays the complete wall as a 4-sided border around [child].
///
/// Forces a square aspect ratio. Tile size is computed from the available
/// space so that 17 stacks per side always fit without overflow.
///
/// 68 stack positions (136 tiles / 2 per stack), 17 per side.
/// Dead wall: 7 stacks at the right end of the bottom wall (positions 34-40).
/// Live wall: remaining 61 positions, drawn counterclockwise from position 41.
/// Dora indicators shown face-up on the dead wall.
class WallDisplay extends StatefulWidget {
  final int wallRemaining;
  final int deadWallCount;
  final List<Tile> doraIndicators;
  final int doraRevealed;
  final Widget child;

  const WallDisplay({
    super.key,
    required this.wallRemaining,
    required this.deadWallCount,
    required this.doraIndicators,
    required this.doraRevealed,
    required this.child,
  });

  @override
  State<WallDisplay> createState() => _WallDisplayState();
}

class _WallDisplayState extends State<WallDisplay>
    with SingleTickerProviderStateMixin {
  static const _perSide = 17;
  static const _deadWallStart = 34;
  static const _livePositions = 61;
  static const _gap = 1.0;

  late AnimationController _drawAnim;
  int _animStack = -1;
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
      final oldFrontDraw = _livePositions - oldActive;
      _animStack = _drawOrderToGlobal(oldFrontDraw);
      _animTopOnly = old.wallRemaining.isEven;
      _drawAnim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _drawAnim.dispose();
    super.dispose();
  }

  int _drawOrderToGlobal(int d) {
    if (d < 10) return 41 + d;
    if (d < 27) return 51 + (d - 10);
    return d - 27;
  }

  int _globalToDrawOrder(int g) {
    if (g >= 41 && g <= 50) return g - 41;
    if (g >= 51 && g <= 67) return 10 + (g - 51);
    if (g >= 0 && g <= 33) return 27 + g;
    return -1;
  }

  int _liveTileCount(int g) {
    final d = _globalToDrawOrder(g);
    if (d < 0) return 0;
    final active = (widget.wallRemaining + 1) ~/ 2;
    final empty = _livePositions - active;
    if (d < empty) return 0;
    if (d == empty && widget.wallRemaining.isOdd) return 1;
    return 2;
  }

  Tile? _doraAt(int localIdx) {
    final slot = localIdx - 2;
    if (slot >= 0 &&
        slot < widget.doraRevealed &&
        slot < widget.doraIndicators.length) {
      return widget.doraIndicators[slot];
    }
    return null;
  }

  /// Compute tile width from available square side length.
  /// Bottom wall is widest: 17 stacks + 0.5w gap = 17.5w + 17 gap pixels.
  /// Wall thickness on each side = 1.4w + 4.
  /// Constraint: 17.5w + 17 + 2*(1.4w + 4) ≤ side
  ///   → 20.3w ≤ side - 25  →  w = (side - 25) / 20.3
  TileSize _tileSizeFromSide(double side) {
    final w = ((side - 25) / 20.3).clamp(6.0, 30.0);
    return TileSize(width: w, height: w * 1.4);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        final ts = _tileSizeFromSide(side);
        final wt = ts.height + 4;

        return SizedBox(
          width: side,
          height: side,
          child: Stack(
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
                child: Center(child: _buildTopSide(ts)),
              ),
              // Right wall (indices 17-33, top to bottom)
              Positioned(
                right: 0,
                top: wt,
                bottom: wt,
                child: Center(child: _buildRightSide(ts)),
              ),
              // Bottom wall: live (41-50) + gap + dead wall (34-40)
              Positioned(
                bottom: 0,
                left: wt,
                right: wt,
                child: Center(child: _buildBottomSide(ts)),
              ),
              // Left wall (indices 51-67, top=67 to bottom=51)
              Positioned(
                left: 0,
                top: wt,
                bottom: wt,
                child: Center(child: _buildLeftSide(ts)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Side builders ─────────────────────────────────────

  Widget _buildTopSide(TileSize ts) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          _perSide, (i) => _liveStack(i, ts, vertical: false)),
    );
  }

  Widget _buildRightSide(TileSize ts) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          _perSide, (i) => _liveStack(17 + i, ts, vertical: true)),
    );
  }

  Widget _buildLeftSide(TileSize ts) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          _perSide, (i) => _liveStack(67 - i, ts, vertical: true)),
    );
  }

  Widget _buildBottomSide(TileSize ts) {
    final children = <Widget>[];

    // Live wall portion (global 50 down to 41)
    for (int g = 50; g >= 41; g--) {
      children.add(_liveStack(g, ts, vertical: false));
    }

    // Visual gap between live and dead wall
    children.add(SizedBox(width: ts.width * 0.5));

    // Dead wall (global 40 down to 34, local 0 to 6)
    for (int g = 40; g >= _deadWallStart; g--) {
      final local = 40 - g;
      children.add(_deadWallStack(local, ts));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  // ─── Stack widgets ─────────────────────────────────────

  Widget _liveStack(int globalIdx, TileSize ts, {required bool vertical}) {
    final stackW = ts.width + _gap;
    final stackH = ts.height + 4;
    final boxW = vertical ? stackH : stackW;
    final boxH = vertical ? stackW : stackH;

    int count = _liveTileCount(globalIdx);
    final isAnim = globalIdx == _animStack && _drawAnim.isAnimating;
    if (isAnim) {
      count = _animTopOnly ? 2 : 1;
    }

    if (count == 0) {
      return SizedBox(width: boxW, height: boxH);
    }

    Widget stack = _tileStack(ts, count, isAnim);
    if (vertical) {
      stack = RotatedBox(quarterTurns: 1, child: stack);
    }
    return SizedBox(width: boxW, height: boxH, child: Center(child: stack));
  }

  Widget _deadWallStack(int localIdx, TileSize ts) {
    final stackW = ts.width + _gap;
    final stackH = ts.height + 4;

    final dora = _doraAt(localIdx);
    Widget stack;
    if (dora != null) {
      stack = SizedBox(
        width: ts.width,
        height: ts.height + 3,
        child: Stack(
          children: [
            Positioned(bottom: 0, left: 0, child: TileBack(size: ts)),
            Positioned(
                top: 0,
                left: 0,
                child: TileWidget(tile: dora, size: ts)),
          ],
        ),
      );
    } else {
      stack = _tileStack(ts, 2, false);
    }

    return SizedBox(width: stackW, height: stackH, child: Center(child: stack));
  }

  // ─── Shared rendering ──────────────────────────────────

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
