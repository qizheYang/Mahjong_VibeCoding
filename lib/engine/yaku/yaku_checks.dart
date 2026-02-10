import '../tile/tile_constants.dart';
import '../win/hand_parser.dart';
import '../state/meld.dart';
import 'hand_context.dart';

/// Individual yaku check functions. Each returns true if the yaku is present.
/// All functions are pure — they depend only on the hand context and partition.
class YakuChecks {
  YakuChecks._();

  // ==========================================================================
  // Helper: build a combined list of all mentsu (from partition + declared melds)
  // ==========================================================================

  static List<_CombinedSet> _allSets(HandPartition partition, HandContext ctx) {
    final sets = <_CombinedSet>[];
    for (final m in partition.mentsu) {
      sets.add(_CombinedSet(
        kinds: m.kinds,
        isShuntsu: m.type == MentsuType.shuntsu,
        isOpen: false,
        isKan: false,
      ));
    }
    for (final meld in ctx.melds) {
      if (meld.type == MeldType.chi) {
        sets.add(_CombinedSet(
          kinds: meld.kinds,
          isShuntsu: true,
          isOpen: true,
          isKan: false,
        ));
      } else {
        sets.add(_CombinedSet(
          kinds: [meld.tiles.first.kind, meld.tiles.first.kind, meld.tiles.first.kind],
          isShuntsu: false,
          isOpen: meld.isOpen,
          isKan: meld.isKan,
        ));
      }
    }
    return sets;
  }

  /// Determine the wait type for the winning tile within the partition.
  static WaitType getWaitType(HandPartition partition, HandContext ctx) {
    final winKind = ctx.winningTile.kind;

    // Check if the winning tile is the pair
    if (partition.pairKind == winKind) {
      // Could be shanpon or tanki. If a koutsu also uses this kind, it's shanpon.
      final hasKoutsuOfSameKind = partition.mentsu.any(
        (m) => m.type == MentsuType.koutsu && m.startKind == winKind,
      );
      if (hasKoutsuOfSameKind) return WaitType.shanpon;
      return WaitType.tanki;
    }

    // Check within each shuntsu
    for (final m in partition.mentsu) {
      if (m.type != MentsuType.shuntsu) continue;
      if (!m.kinds.contains(winKind)) continue;

      final pos = winKind - m.startKind; // 0, 1, or 2
      if (pos == 1) return WaitType.kanchan; // middle wait

      // Edge wait (penchan) or two-sided (ryanmen)
      final startNum = TileConstants.numberOf(m.startKind);
      if (pos == 0) {
        // Winning tile is the lowest in the sequence
        if (startNum == 7) return WaitType.penchan; // 7-8-9, waiting on 7
        return WaitType.ryanmen;
      } else {
        // pos == 2, winning tile is the highest
        if (startNum == 1) return WaitType.penchan; // 1-2-3, waiting on 3
        return WaitType.ryanmen;
      }
    }

    // Koutsu match (shanpon)
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu && m.startKind == winKind) {
        return WaitType.shanpon;
      }
    }

    return WaitType.other;
  }

  // ==========================================================================
  // 1 han yaku
  // ==========================================================================

  static bool isRiichi(HandContext ctx) => ctx.isRiichi && ctx.isMenzen;

  static bool isIppatsu(HandContext ctx) => ctx.isIppatsu;

  static bool isMenzenTsumo(HandContext ctx) => ctx.isTsumo && ctx.isMenzen;

  static bool isPinfu(HandContext ctx, HandPartition partition) {
    if (!ctx.isMenzen) return false;

    // All sets must be shuntsu
    if (partition.mentsu.any((m) => m.type != MentsuType.shuntsu)) return false;
    if (ctx.melds.isNotEmpty) return false; // should be redundant with isMenzen

    // Pair must not be yakuhai
    final pairKind = partition.pairKind!;
    if (_isYakuhaiKind(pairKind, ctx.seatWind, ctx.roundWind)) return false;

    // Wait must be ryanmen (two-sided)
    return getWaitType(partition, ctx) == WaitType.ryanmen;
  }

  static bool isTanyao(HandContext ctx, HandPartition partition) {
    // All tiles (closed + melds) must be simples (2-8 suited, no terminals/honors)
    for (final kind in ctx.allKinds) {
      if (TileConstants.isTerminalOrHonor(kind)) return false;
    }
    return true;
  }

  static bool isIipeiko(HandContext ctx, HandPartition partition) {
    if (!ctx.isMenzen) return false;
    // Two identical shuntsu in the closed hand
    final shuntsuKinds = partition.mentsu
        .where((m) => m.type == MentsuType.shuntsu)
        .map((m) => m.startKind)
        .toList();
    final seen = <int>{};
    int duplicates = 0;
    for (final k in shuntsuKinds) {
      if (!seen.add(k)) duplicates++;
    }
    return duplicates == 1; // exactly one pair of identical shuntsu
  }

  // === Yakuhai ===

  static bool isYakuhaiHaku(HandContext ctx, HandPartition partition) =>
      _hasYakuhaiTriplet(ctx, partition, 31);

  static bool isYakuhaiHatsu(HandContext ctx, HandPartition partition) =>
      _hasYakuhaiTriplet(ctx, partition, 32);

  static bool isYakuhaiChun(HandContext ctx, HandPartition partition) =>
      _hasYakuhaiTriplet(ctx, partition, 33);

  static bool isYakuhaiSeatWind(HandContext ctx, HandPartition partition) =>
      _hasYakuhaiTriplet(ctx, partition, TileConstants.windKind(ctx.seatWind));

  static bool isYakuhaiRoundWind(HandContext ctx, HandPartition partition) =>
      _hasYakuhaiTriplet(ctx, partition, TileConstants.windKind(ctx.roundWind));

  static bool _hasYakuhaiTriplet(HandContext ctx, HandPartition partition, int kind) {
    // Check closed koutsu
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu && m.startKind == kind) return true;
    }
    // Check open melds (pon/kan)
    for (final meld in ctx.melds) {
      if (meld.type != MeldType.chi && meld.tiles.first.kind == kind) return true;
    }
    return false;
  }

  // === Special 1 han ===

  static bool isHaitei(HandContext ctx) => ctx.isLastTile && ctx.isTsumo;
  static bool isHoutei(HandContext ctx) => ctx.isLastTile && !ctx.isTsumo;
  static bool isRinshan(HandContext ctx) => ctx.isAfterKan && ctx.isTsumo;
  static bool isChankan(HandContext ctx) => ctx.isChankan;

  // ==========================================================================
  // 2 han yaku
  // ==========================================================================

  static bool isDoubleRiichi(HandContext ctx) => ctx.isDoubleRiichi;

  static bool isChanta(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    if (allSets.isEmpty) return false;

    // Every set must contain a terminal or honor
    for (final s in allSets) {
      if (!s.kinds.any((k) => TileConstants.isTerminalOrHonor(k))) return false;
    }
    // Pair must be terminal or honor
    if (partition.pairKind != null &&
        !TileConstants.isTerminalOrHonor(partition.pairKind!)) {
      return false;
    }

    // Must have at least one shuntsu (otherwise it's honroutou/toitoi)
    if (!allSets.any((s) => s.isShuntsu)) return false;
    // Must have at least one honor (otherwise it's junchan)
    final allKinds = <int>[...allSets.expand((s) => s.kinds), if (partition.pairKind != null) partition.pairKind!];
    if (!allKinds.any((k) => TileConstants.isHonor(k))) return false;

    return true;
  }

  static bool isSanshokuDoujun(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    final shuntsu = allSets.where((s) => s.isShuntsu).toList();
    if (shuntsu.length < 3) return false;

    // Find a number that has a shuntsu in all three suits
    for (final s in shuntsu) {
      final num = TileConstants.numberOf(s.kinds.first);
      final suit = TileConstants.suitOf(s.kinds.first);
      final hasAllSuits = [0, 1, 2].every((targetSuit) =>
          targetSuit == suit ||
          shuntsu.any((s2) =>
              TileConstants.suitOf(s2.kinds.first) == targetSuit &&
              TileConstants.numberOf(s2.kinds.first) == num));
      if (hasAllSuits) return true;
    }
    return false;
  }

  static bool isIttsu(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    final shuntsu = allSets.where((s) => s.isShuntsu).toList();
    if (shuntsu.length < 3) return false;

    // 1-2-3, 4-5-6, 7-8-9 of the same suit
    for (int suit = 0; suit < 3; suit++) {
      final suitShuntsu = shuntsu
          .where((s) => TileConstants.suitOf(s.kinds.first) == suit)
          .map((s) => TileConstants.numberOf(s.kinds.first))
          .toSet();
      if (suitShuntsu.contains(1) &&
          suitShuntsu.contains(4) &&
          suitShuntsu.contains(7)) {
        return true;
      }
    }
    return false;
  }

  static bool isToitoi(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    return allSets.every((s) => !s.isShuntsu);
  }

  static bool isSanAnkou(HandContext ctx, HandPartition partition) {
    int concealedTriplets = 0;

    // Count concealed koutsu from the partition
    for (final m in partition.mentsu) {
      if (m.type == MentsuType.koutsu) {
        // If ron and this koutsu was completed by the winning tile, it's open
        if (!ctx.isTsumo && m.startKind == ctx.winningTile.kind) {
          // Check if the wait type is shanpon — if so, this set is open for ron
          final waitType = getWaitType(partition, ctx);
          if (waitType == WaitType.shanpon) continue;
        }
        concealedTriplets++;
      }
    }

    // Count closed kan from melds
    for (final meld in ctx.melds) {
      if (meld.type == MeldType.closedKan) concealedTriplets++;
    }

    return concealedTriplets == 3;
  }

  static bool isSanshokuDoukou(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    final koutsu = allSets.where((s) => !s.isShuntsu).toList();
    if (koutsu.length < 3) return false;

    for (final k in koutsu) {
      if (!TileConstants.isSuited(k.kinds.first)) continue;
      final num = TileConstants.numberOf(k.kinds.first);
      final suit = TileConstants.suitOf(k.kinds.first);
      final hasAllSuits = [0, 1, 2].every((targetSuit) =>
          targetSuit == suit ||
          koutsu.any((k2) =>
              TileConstants.isSuited(k2.kinds.first) &&
              TileConstants.suitOf(k2.kinds.first) == targetSuit &&
              TileConstants.numberOf(k2.kinds.first) == num));
      if (hasAllSuits) return true;
    }
    return false;
  }

  static bool isSankantsu(HandContext ctx, HandPartition partition) {
    int kanCount = ctx.melds.where((m) => m.isKan).length;
    return kanCount == 3;
  }

  static bool isHonroutou(HandContext ctx, HandPartition partition) {
    // All tiles are terminals or honors
    for (final kind in ctx.allKinds) {
      if (!TileConstants.isTerminalOrHonor(kind)) return false;
    }
    return true;
  }

  static bool isShousangen(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    int dragonTriplets = 0;
    bool dragonPair = false;

    for (final s in allSets) {
      if (!s.isShuntsu && s.kinds.first >= 31) dragonTriplets++;
    }
    if (partition.pairKind != null && partition.pairKind! >= 31) {
      dragonPair = true;
    }

    return dragonTriplets == 2 && dragonPair;
  }

  static bool isChiitoitsu(HandContext ctx, HandPartition partition) {
    if (!ctx.isMenzen) return false;
    if (ctx.melds.isNotEmpty) return false;
    // Check if the closed hand is exactly 7 pairs
    final counts = ctx.kindCounts;
    int pairs = 0;
    for (int k = 0; k < 34; k++) {
      if (counts[k] == 2) {
        pairs++;
      } else if (counts[k] != 0) {
        return false;
      }
    }
    return pairs == 7;
  }

  // ==========================================================================
  // 3 han yaku
  // ==========================================================================

  static bool isHonitsu(HandContext ctx, HandPartition partition) {
    // One suit + honors only
    final allKinds = ctx.allKinds;
    int? suit;
    for (final kind in allKinds) {
      if (TileConstants.isHonor(kind)) continue;
      final s = TileConstants.suitOf(kind);
      if (suit == null) {
        suit = s;
      } else if (s != suit) {
        return false;
      }
    }
    // Must have at least one honor
    if (!allKinds.any((k) => TileConstants.isHonor(k))) return false;
    return suit != null;
  }

  static bool isJunchan(HandContext ctx, HandPartition partition) {
    final allSets = _allSets(partition, ctx);
    if (allSets.isEmpty) return false;

    // Every set must contain a terminal
    for (final s in allSets) {
      if (!s.kinds.any((k) => TileConstants.isTerminal(k))) return false;
    }
    // Pair must be terminal
    if (partition.pairKind != null &&
        !TileConstants.isTerminal(partition.pairKind!)) {
      return false;
    }
    // Must have at least one shuntsu
    if (!allSets.any((s) => s.isShuntsu)) return false;
    // No honors
    final allKinds = <int>[...allSets.expand((s) => s.kinds), if (partition.pairKind != null) partition.pairKind!];
    if (allKinds.any((k) => TileConstants.isHonor(k))) return false;

    return true;
  }

  static bool isRyanpeikou(HandContext ctx, HandPartition partition) {
    if (!ctx.isMenzen) return false;
    final shuntsuKinds = partition.mentsu
        .where((m) => m.type == MentsuType.shuntsu)
        .map((m) => m.startKind)
        .toList();
    if (shuntsuKinds.length != 4) return false;
    shuntsuKinds.sort();
    // Must be two pairs of identical shuntsu
    return shuntsuKinds[0] == shuntsuKinds[1] &&
        shuntsuKinds[2] == shuntsuKinds[3];
  }

  // ==========================================================================
  // 6 han
  // ==========================================================================

  static bool isChinitsu(HandContext ctx, HandPartition partition) {
    // All tiles are one suit, no honors
    final allKinds = ctx.allKinds;
    if (allKinds.any((k) => TileConstants.isHonor(k))) return false;
    int? suit;
    for (final kind in allKinds) {
      final s = TileConstants.suitOf(kind);
      if (suit == null) {
        suit = s;
      } else if (s != suit) {
        return false;
      }
    }
    return suit != null;
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  static bool _isYakuhaiKind(int kind, int seatWind, int roundWind) {
    if (kind >= 31) return true; // dragon
    if (kind == TileConstants.windKind(seatWind)) return true;
    if (kind == TileConstants.windKind(roundWind)) return true;
    return false;
  }
}

// Internal helper
class _CombinedSet {
  final List<int> kinds;
  final bool isShuntsu;
  final bool isOpen;
  final bool isKan;

  const _CombinedSet({
    required this.kinds,
    required this.isShuntsu,
    required this.isOpen,
    required this.isKan,
  });
}

enum WaitType { ryanmen, kanchan, penchan, shanpon, tanki, other }
