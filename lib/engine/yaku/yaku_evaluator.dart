import '../win/hand_parser.dart';
import '../win/win_detector.dart';
import 'hand_context.dart';
import 'yaku_type.dart';
import 'yaku_checks.dart';
import 'yakuman_checks.dart';

/// Result of yaku evaluation for a winning hand.
class YakuResult {
  final List<YakuType> yakuList;
  final HandPartition? partition;
  final bool isChiitoitsuForm;

  const YakuResult({
    this.yakuList = const [],
    this.partition,
    this.isChiitoitsuForm = false,
  });

  bool get hasYaku => yakuList.isNotEmpty;
  bool get hasYakuman => yakuList.any((y) => y.isYakuman);

  int totalHan(bool isMenzen) {
    if (hasYakuman) {
      return yakuList.where((y) => y.isYakuman).length * 13;
    }
    return yakuList.fold(0, (sum, y) => sum + y.han(isMenzen));
  }
}

/// Master yaku evaluator: checks all partitions and returns the best result.
class YakuEvaluator {
  YakuEvaluator._();

  static YakuResult evaluate(HandContext ctx) {
    final results = <YakuResult>[];

    // Get all valid partitions of the closed hand
    final targetSets = 4 - ctx.melds.length;
    final partitions = HandParser.findAllPartitions(
      List.from(ctx.kindCounts),
      targetSets,
    );

    // Evaluate each standard partition
    for (final partition in partitions) {
      final yakuList = _checkAllYaku(ctx, partition);
      if (yakuList.isNotEmpty) {
        results.add(YakuResult(yakuList: yakuList, partition: partition));
      }
    }

    // Check chiitoitsu separately
    if (ctx.melds.isEmpty && WinDetector.isChiitoitsu(ctx.kindCounts)) {
      final yakuList = _checkChiitoitsuYaku(ctx);
      if (yakuList.isNotEmpty) {
        results.add(YakuResult(
          yakuList: yakuList,
          isChiitoitsuForm: true,
        ));
      }
    }

    if (results.isEmpty) return const YakuResult();

    // Pick the result with the highest han count
    results.sort((a, b) {
      final aHan = a.totalHan(ctx.isMenzen);
      final bHan = b.totalHan(ctx.isMenzen);
      return bHan.compareTo(aHan);
    });

    return results.first;
  }

  static List<YakuType> _checkAllYaku(HandContext ctx, HandPartition partition) {
    final yakuList = <YakuType>[];

    // Check yakuman first
    final yakuman = _checkYakuman(ctx, partition);
    if (yakuman.isNotEmpty) return yakuman;

    // === 1 han ===
    if (YakuChecks.isRiichi(ctx)) yakuList.add(YakuType.riichi);
    if (YakuChecks.isIppatsu(ctx)) yakuList.add(YakuType.ippatsu);
    if (YakuChecks.isMenzenTsumo(ctx)) yakuList.add(YakuType.menzenTsumo);
    if (YakuChecks.isPinfu(ctx, partition)) yakuList.add(YakuType.pinfu);
    if (YakuChecks.isTanyao(ctx, partition)) yakuList.add(YakuType.tanyao);

    // Iipeiko and ryanpeikou are mutually exclusive
    if (YakuChecks.isRyanpeikou(ctx, partition)) {
      yakuList.add(YakuType.ryanpeikou);
    } else if (YakuChecks.isIipeiko(ctx, partition)) {
      yakuList.add(YakuType.iipeiko);
    }

    if (YakuChecks.isYakuhaiHaku(ctx, partition)) yakuList.add(YakuType.yakuhaiHaku);
    if (YakuChecks.isYakuhaiHatsu(ctx, partition)) yakuList.add(YakuType.yakuhaiHatsu);
    if (YakuChecks.isYakuhaiChun(ctx, partition)) yakuList.add(YakuType.yakuhaiChun);
    if (YakuChecks.isYakuhaiSeatWind(ctx, partition)) yakuList.add(YakuType.yakuhaiSeatWind);
    // Round wind stacks with seat wind (e.g. East dealer in East round = 2 han)
    if (YakuChecks.isYakuhaiRoundWind(ctx, partition)) {
      yakuList.add(YakuType.yakuhaiRoundWind);
    }

    if (YakuChecks.isHaitei(ctx)) yakuList.add(YakuType.haitei);
    if (YakuChecks.isHoutei(ctx)) yakuList.add(YakuType.houtei);
    if (YakuChecks.isRinshan(ctx)) yakuList.add(YakuType.rinshan);
    if (YakuChecks.isChankan(ctx)) yakuList.add(YakuType.chankan);

    // === 2 han ===
    if (YakuChecks.isDoubleRiichi(ctx)) {
      // Replace riichi with double riichi
      yakuList.remove(YakuType.riichi);
      yakuList.add(YakuType.doubleRiichi);
    }

    // Chanta/junchan are mutually exclusive
    if (YakuChecks.isJunchan(ctx, partition)) {
      yakuList.add(YakuType.junchan);
    } else if (YakuChecks.isChanta(ctx, partition)) {
      yakuList.add(YakuType.chanta);
    }

    if (YakuChecks.isSanshokuDoujun(ctx, partition)) yakuList.add(YakuType.sanshokuDoujun);
    if (YakuChecks.isIttsu(ctx, partition)) yakuList.add(YakuType.ittsu);
    if (YakuChecks.isToitoi(ctx, partition)) yakuList.add(YakuType.toitoi);
    if (YakuChecks.isSanAnkou(ctx, partition)) yakuList.add(YakuType.sanAnkou);
    if (YakuChecks.isSanshokuDoukou(ctx, partition)) yakuList.add(YakuType.sanshokuDoukou);
    if (YakuChecks.isSankantsu(ctx, partition)) yakuList.add(YakuType.sankantsu);
    if (YakuChecks.isShousangen(ctx, partition)) yakuList.add(YakuType.shousangen);

    // Honroutou (stacks with toitoi)
    if (YakuChecks.isHonroutou(ctx, partition)) yakuList.add(YakuType.honroutou);

    // === 3+ han ===
    // Chinitsu/honitsu are mutually exclusive
    if (YakuChecks.isChinitsu(ctx, partition)) {
      yakuList.add(YakuType.chinitsu);
    } else if (YakuChecks.isHonitsu(ctx, partition)) {
      yakuList.add(YakuType.honitsu);
    }

    return yakuList;
  }

  static List<YakuType> _checkYakuman(HandContext ctx, HandPartition partition) {
    final yakuman = <YakuType>[];

    if (YakumanChecks.isTenhou(ctx)) yakuman.add(YakuType.tenhou);
    if (YakumanChecks.isChiihou(ctx)) yakuman.add(YakuType.chiihou);
    if (YakumanChecks.isKokushiMusou(ctx)) yakuman.add(YakuType.kokushiMusou);
    if (YakumanChecks.isSuuankou(ctx, partition)) yakuman.add(YakuType.suuankou);
    if (YakumanChecks.isDaisangen(ctx, partition)) yakuman.add(YakuType.daisangen);
    if (YakumanChecks.isDaisuushii(ctx, partition)) {
      yakuman.add(YakuType.daisuushii);
    } else if (YakumanChecks.isShousuushii(ctx, partition)) {
      yakuman.add(YakuType.shousuushii);
    }
    if (YakumanChecks.isTsuuiisou(ctx)) yakuman.add(YakuType.tsuuiisou);
    if (YakumanChecks.isChinroutou(ctx)) yakuman.add(YakuType.chinroutou);
    if (YakumanChecks.isRyuuiisou(ctx)) yakuman.add(YakuType.ryuuiisou);
    if (YakumanChecks.isChuurenPoutou(ctx)) yakuman.add(YakuType.chuurenPoutou);
    if (YakumanChecks.isSuukantsu(ctx)) yakuman.add(YakuType.suukantsu);

    return yakuman;
  }

  static List<YakuType> _checkChiitoitsuYaku(HandContext ctx) {
    final yakuList = <YakuType>[YakuType.chiitoitsu];

    if (YakuChecks.isRiichi(ctx)) yakuList.add(YakuType.riichi);
    if (YakuChecks.isIppatsu(ctx)) yakuList.add(YakuType.ippatsu);
    if (YakuChecks.isMenzenTsumo(ctx)) yakuList.add(YakuType.menzenTsumo);
    if (YakuChecks.isTanyao(ctx, const HandPartition())) yakuList.add(YakuType.tanyao);
    if (YakuChecks.isHaitei(ctx)) yakuList.add(YakuType.haitei);
    if (YakuChecks.isHoutei(ctx)) yakuList.add(YakuType.houtei);

    if (YakuChecks.isDoubleRiichi(ctx)) {
      yakuList.remove(YakuType.riichi);
      yakuList.add(YakuType.doubleRiichi);
    }

    // Honitsu/chinitsu can stack with chiitoitsu
    if (YakuChecks.isChinitsu(ctx, const HandPartition())) {
      yakuList.add(YakuType.chinitsu);
    } else if (YakuChecks.isHonitsu(ctx, const HandPartition())) {
      yakuList.add(YakuType.honitsu);
    }

    if (YakuChecks.isHonroutou(ctx, const HandPartition())) {
      yakuList.add(YakuType.honroutou);
    }

    return yakuList;
  }
}
