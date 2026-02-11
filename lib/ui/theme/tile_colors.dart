import 'package:flutter/material.dart';
import '../../engine/tile/tile_type.dart';

class TileColors {
  TileColors._();

  static const Color tableBg = Color(0xFF1B5E20);
  static const Color tileFace = Color(0xFFFFF8E1);
  static const Color tileBack = Color(0xFF1565C0);
  static const Color tileBorder = Color(0xFF5D4037);
  static const Color tileSelected = Color(0xFFFFD54F);
  static const Color redDoraBg = Color(0xFFFFEBEE);

  static Color textColor(TileType type) {
    switch (type) {
      case TileType.man:
        return const Color(0xFF212121);
      case TileType.pin:
        return const Color(0xFF0D47A1);
      case TileType.sou:
        return const Color(0xFF1B5E20);
      case TileType.wind:
        return const Color(0xFF212121);
      case TileType.dragon:
        return const Color(0xFF212121);
      case TileType.flower:
        return const Color(0xFFC62828);
    }
  }

  static String suitKanji(TileType type) {
    switch (type) {
      case TileType.man:
        return '萬';
      case TileType.pin:
        return '筒';
      case TileType.sou:
        return '索';
      case TileType.wind:
        return '';
      case TileType.dragon:
        return '';
      case TileType.flower:
        return '花';
    }
  }

  static String tileLabel(TileType type, int number) {
    switch (type) {
      case TileType.man:
      case TileType.pin:
      case TileType.sou:
        return '$number';
      case TileType.wind:
        return const ['東', '南', '西', '北'][number - 1];
      case TileType.dragon:
        return const ['　', '發', '中'][number - 1]; // haku is blank
      case TileType.flower:
        return '花';
    }
  }

  static Color dragonColor(int number) {
    switch (number) {
      case 1:
        return const Color(0xFF9E9E9E); // haku - grey border
      case 2:
        return const Color(0xFF2E7D32); // hatsu - green
      case 3:
        return const Color(0xFFC62828); // chun - red
      default:
        return const Color(0xFF212121);
    }
  }
}
