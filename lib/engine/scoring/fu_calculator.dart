import '../tile/tile_constants.dart';
import '../state/meld.dart';
import '../win/hand_parser.dart';
import '../yaku/hand_context.dart';
import '../yaku/yaku_checks.dart';

/// Calculates fu (minipoints) for a winning hand.
class FuCalculator {
  FuCalculator._();

  /// Calculate fu for a standard partition.
  ///
  /// Returns the fu value rounded up to the nearest 10.
  static int calculate(HandPartition partition, HandContext ctx) {
    // Chiitoitsu is always 25 fu
    // (handled by caller checking isChiitoitsuForm)

    int fu = 0;

    // Base fu
    if (ctx.isTsumo) {
      fu = 20;
    } else if (ctx.isMenzen) {
      fu = 30; // closed ron
    } else {
      fu = 20; // open hand
    }

    // Fu from closed hand sets (partition mentsu)
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu) {
        final isTerminalOrHonor = TileConstants.isTerminalOrHonor(m.startKind);
        // Closed koutsu
        fu += isTerminalOrHonor ? 8 : 4;
      }
      // Shuntsu: 0 fu
    }

    // Fu from declared melds
    for (final meld in ctx.melds) {
      final kind = meld.tiles.first.kind;
      final isTerminalOrHonor = TileConstants.isTerminalOrHonor(kind);

      switch (meld.type) {
        case MeldType.pon:
          fu += isTerminalOrHonor ? 4 : 2; // open triplet
        case MeldType.closedKan:
          fu += isTerminalOrHonor ? 32 : 16; // closed kan
        case MeldType.openKan:
        case MeldType.addedKan:
          fu += isTerminalOrHonor ? 16 : 8; // open kan
        case MeldType.chi:
          break; // 0 fu
      }
    }

    // Fu from pair
    if (partition.pairKind != null) {
      final pairKind = partition.pairKind!;
      // Dragon pair: +2
      if (pairKind >= 31) fu += 2;
      // Seat wind pair: +2
      if (pairKind == TileConstants.windKind(ctx.seatWind)) fu += 2;
      // Round wind pair: +2 (can stack with seat wind)
      if (pairKind == TileConstants.windKind(ctx.roundWind)) fu += 2;
    }

    // Fu from wait type
    final waitType = YakuChecks.getWaitType(partition, ctx);
    if (waitType == WaitType.kanchan ||
        waitType == WaitType.penchan ||
        waitType == WaitType.tanki) {
      fu += 2;
    }

    // Tsumo fu (except for pinfu tsumo)
    if (ctx.isTsumo) {
      // Check if this is a pinfu hand
      final isPinfu = YakuChecks.isPinfu(ctx, partition);
      if (!isPinfu) {
        fu += 2;
      }
    }

    // Special case: open pinfu-like hand (all shuntsu, non-yakuhai pair, ryanmen)
    // gets minimum 30 fu even though calculation might give 20
    if (!ctx.isMenzen && fu < 30 && !ctx.isTsumo) {
      // Actually for open hand ron the base is already 20 + potential 0 from sets
      // The minimum for an open hand is 20 fu (which rounds to 20).
      // No special minimum needed beyond the rounding.
    }

    // Pinfu tsumo: exactly 20 fu (no rounding)
    if (ctx.isTsumo && ctx.isMenzen && YakuChecks.isPinfu(ctx, partition)) {
      return 20;
    }

    // Round up to nearest 10
    return ((fu + 9) ~/ 10) * 10;
  }

  /// Fu for chiitoitsu: always 25 (no rounding).
  static int chiitoitsuFu() => 25;
}
