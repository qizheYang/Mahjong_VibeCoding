import '../tile/tile_constants.dart';
import '../yaku/hand_context.dart';
import '../yaku/yaku_type.dart';

/// Counts total han for a winning hand.
class HanCounter {
  HanCounter._();

  /// Sum han from yaku list + dora.
  static int count(List<YakuType> yakuList, HandContext ctx) {
    // If yakuman, return 13 per yakuman
    final yakuman = yakuList.where((y) => y.isYakuman).toList();
    if (yakuman.isNotEmpty) {
      return yakuman.length * 13;
    }

    int han = 0;

    // Sum yaku han
    for (final yaku in yakuList) {
      han += yaku.han(ctx.isMenzen);
    }

    // Add dora
    han += countDora(ctx);

    return han;
  }

  /// Count all dora (regular + ura + red).
  static int countDora(HandContext ctx) {
    return countRegularDora(ctx) + countUraDora(ctx) + countRedDora(ctx);
  }

  /// Count regular dora (from dora indicators).
  static int countRegularDora(HandContext ctx) {
    int count = 0;
    final allKinds = ctx.allKinds;
    for (final indicator in ctx.doraIndicators) {
      final doraKind = TileConstants.doraFromIndicator(indicator.kind);
      count += allKinds.where((k) => k == doraKind).length;
    }
    return count;
  }

  /// Count ura-dora (only if riichi).
  static int countUraDora(HandContext ctx) {
    if (!ctx.isRiichi && !ctx.isDoubleRiichi) return 0;
    int count = 0;
    final allKinds = ctx.allKinds;
    for (final indicator in ctx.uraDoraIndicators) {
      final uraDoraKind = TileConstants.doraFromIndicator(indicator.kind);
      count += allKinds.where((k) => k == uraDoraKind).length;
    }
    return count;
  }

  /// Count red dora tiles in the hand.
  static int countRedDora(HandContext ctx) => ctx.redDoraCount;
}
