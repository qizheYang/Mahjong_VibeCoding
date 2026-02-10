import '../tile/tile_constants.dart';
import '../state/meld.dart';
import '../win/hand_parser.dart';
import '../win/win_detector.dart';
import 'hand_context.dart';

/// Yakuman check functions.
class YakumanChecks {
  YakumanChecks._();

  static bool isKokushiMusou(HandContext ctx) {
    if (!ctx.isMenzen || ctx.melds.isNotEmpty) return false;
    return WinDetector.isKokushi(ctx.kindCounts);
  }

  static bool isSuuankou(HandContext ctx, HandPartition partition) {
    if (!ctx.isMenzen) return false;

    int concealedTriplets = 0;
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu) {
        // For ron + shanpon wait, the completed triplet is considered open
        if (!ctx.isTsumo && m.startKind == ctx.winningTile.kind) {
          // Only counts as concealed if the wait is tanki (not shanpon)
          final isTanki = partition.pairKind == ctx.winningTile.kind &&
              !partition.mentsu.any(
                (m2) => m2.type == MentsuType.koutsu && m2.startKind == ctx.winningTile.kind,
              );
          if (!isTanki) continue;
        }
        concealedTriplets++;
      }
    }

    // Add closed kans
    for (final meld in ctx.melds) {
      if (meld.type == MeldType.closedKan) concealedTriplets++;
    }

    return concealedTriplets == 4;
  }

  static bool isDaisangen(HandContext ctx, HandPartition partition) {
    int dragonTriplets = 0;
    // Check partition koutsu
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu && m.startKind >= 31) dragonTriplets++;
    }
    // Check melds
    for (final meld in ctx.melds) {
      if (meld.type != MeldType.chi && meld.tiles.first.kind >= 31) {
        dragonTriplets++;
      }
    }
    return dragonTriplets == 3;
  }

  static bool isShousuushii(HandContext ctx, HandPartition partition) {
    int windTriplets = 0;
    bool windPair = false;

    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu && m.startKind >= 27 && m.startKind <= 30) {
        windTriplets++;
      }
    }
    for (final meld in ctx.melds) {
      if (meld.type != MeldType.chi) {
        final k = meld.tiles.first.kind;
        if (k >= 27 && k <= 30) windTriplets++;
      }
    }
    if (partition.pairKind != null &&
        partition.pairKind! >= 27 &&
        partition.pairKind! <= 30) {
      windPair = true;
    }

    return windTriplets == 3 && windPair;
  }

  static bool isDaisuushii(HandContext ctx, HandPartition partition) {
    int windTriplets = 0;
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu && m.startKind >= 27 && m.startKind <= 30) {
        windTriplets++;
      }
    }
    for (final meld in ctx.melds) {
      if (meld.type != MeldType.chi) {
        final k = meld.tiles.first.kind;
        if (k >= 27 && k <= 30) windTriplets++;
      }
    }
    return windTriplets == 4;
  }

  static bool isTsuuiisou(HandContext ctx) {
    return ctx.allKinds.every((k) => TileConstants.isHonor(k));
  }

  static bool isChinroutou(HandContext ctx) {
    return ctx.allKinds.every((k) => TileConstants.isTerminal(k));
  }

  static bool isRyuuiisou(HandContext ctx) {
    return ctx.allKinds.every((k) => TileConstants.greenKinds.contains(k));
  }

  static bool isChuurenPoutou(HandContext ctx) {
    if (!ctx.isMenzen || ctx.melds.isNotEmpty) return false;
    final counts = ctx.kindCounts;

    // Must be all one suit
    int? suit;
    for (int k = 0; k < 34; k++) {
      if (counts[k] > 0) {
        if (!TileConstants.isSuited(k)) return false;
        final s = TileConstants.suitOf(k);
        if (suit == null) {
          suit = s;
        } else if (s != suit) {
          return false;
        }
      }
    }
    if (suit == null) return false;

    // Base pattern: 1112345678999 + one extra
    final base = suit * 9;
    // Must have at least: 3x1, 1x2, 1x3, ..., 1x8, 3x9
    final required = [3, 1, 1, 1, 1, 1, 1, 1, 3];
    for (int i = 0; i < 9; i++) {
      if (counts[base + i] < required[i]) return false;
    }
    // Total should be 14
    int total = 0;
    for (int i = 0; i < 9; i++) {
      total += counts[base + i];
    }
    return total == 14;
  }

  static bool isSuukantsu(HandContext ctx) {
    return ctx.melds.where((m) => m.isKan).length == 4;
  }

  static bool isTenhou(HandContext ctx) {
    // Dealer wins on their very first draw
    return ctx.isFirstTurn && ctx.isTsumo && ctx.seatWind == 0;
  }

  static bool isChiihou(HandContext ctx) {
    // Non-dealer wins on their first draw, no calls have been made
    return ctx.isFirstTurn && ctx.isTsumo && ctx.seatWind != 0;
  }
}
