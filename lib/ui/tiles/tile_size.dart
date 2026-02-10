import 'package:flutter/material.dart';

/// Responsive tile sizing based on screen dimensions.
class TileSize {
  final double width;
  final double height;

  const TileSize({required this.width, required this.height});

  double get fontSize => width * 0.45;
  double get smallFontSize => width * 0.3;
  double get borderRadius => width * 0.1;
  double get spacing => width * 0.06;

  /// Standard tile size for the human player's hand.
  factory TileSize.forHand(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final w = (screenWidth / 18).clamp(24.0, 48.0);
    return TileSize(width: w, height: w * 1.4);
  }

  /// Smaller tile size for opponents and discard pools.
  factory TileSize.small(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final w = (screenWidth / 24).clamp(18.0, 36.0);
    return TileSize(width: w, height: w * 1.4);
  }

  /// Tiny tile size for opponent hands (face-down).
  factory TileSize.tiny(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final w = (screenWidth / 32).clamp(14.0, 28.0);
    return TileSize(width: w, height: w * 1.4);
  }
}
