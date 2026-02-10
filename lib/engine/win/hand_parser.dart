import '../tile/tile_constants.dart';

/// Represents one way to decompose a hand into sets and a pair.
class HandPartition {
  final List<Mentsu> mentsu; // groups (triplets or sequences)
  final int? pairKind; // the pair kind (null if no pair yet)

  const HandPartition({this.mentsu = const [], this.pairKind});

  HandPartition withMentsu(Mentsu m) =>
      HandPartition(mentsu: [...mentsu, m], pairKind: pairKind);

  HandPartition withPair(int kind) =>
      HandPartition(mentsu: mentsu, pairKind: kind);

  @override
  String toString() =>
      'Partition(${mentsu.join(", ")}${pairKind != null ? ", pair=$pairKind" : ""})';
}

enum MentsuType { shuntsu, koutsu }

/// A single set (mentsu) within a partition.
class Mentsu {
  final MentsuType type;
  final int startKind; // for shuntsu: lowest kind; for koutsu: the kind

  const Mentsu(this.type, this.startKind);

  List<int> get kinds {
    if (type == MentsuType.koutsu) return [startKind, startKind, startKind];
    return [startKind, startKind + 1, startKind + 2];
  }

  @override
  String toString() => type == MentsuType.koutsu
      ? 'Kou($startKind)'
      : 'Shun($startKind-${startKind + 2})';
}

/// Decomposes a closed hand (as kind counts) into all valid partitions
/// of mentsu (sets) + jantai (pair).
class HandParser {
  HandParser._();

  /// Find all valid partitions of the closed hand.
  ///
  /// [kindCounts] is a 34-element array where kindCounts[k] = number of tiles
  /// of kind k in the closed hand.
  /// [targetSets] is how many mentsu we need from the closed hand
  /// (4 minus the number of declared melds).
  static List<HandPartition> findAllPartitions(
    List<int> kindCounts,
    int targetSets,
  ) {
    final results = <HandPartition>[];
    _backtrack(List.from(kindCounts), targetSets, false, HandPartition(), results);
    return results;
  }

  static void _backtrack(
    List<int> counts,
    int setsNeeded,
    bool hasPair,
    HandPartition current,
    List<HandPartition> results,
  ) {
    if (setsNeeded == 0 && hasPair) {
      // Verify all counts are zero
      if (counts.every((c) => c == 0)) {
        results.add(current);
      }
      return;
    }

    // Find the leftmost kind with tiles remaining
    int firstKind = -1;
    for (int k = 0; k < 34; k++) {
      if (counts[k] > 0) {
        firstKind = k;
        break;
      }
    }
    if (firstKind == -1) return; // no tiles left but we still need sets/pair

    // Try pair (if no pair yet)
    if (!hasPair && counts[firstKind] >= 2) {
      counts[firstKind] -= 2;
      _backtrack(
        counts,
        setsNeeded,
        true,
        current.withPair(firstKind),
        results,
      );
      counts[firstKind] += 2;
    }

    // Try koutsu (triplet)
    if (setsNeeded > 0 && counts[firstKind] >= 3) {
      counts[firstKind] -= 3;
      _backtrack(
        counts,
        setsNeeded - 1,
        hasPair,
        current.withMentsu(Mentsu(MentsuType.koutsu, firstKind)),
        results,
      );
      counts[firstKind] += 3;
    }

    // Try shuntsu (sequence) — only for suited tiles where we can form a run
    if (setsNeeded > 0 &&
        TileConstants.isSuited(firstKind) &&
        TileConstants.numberOf(firstKind) <= 7) {
      final k1 = firstKind;
      final k2 = firstKind + 1;
      final k3 = firstKind + 2;
      // Ensure all three are the same suit
      if (TileConstants.suitOf(k1) == TileConstants.suitOf(k3) &&
          counts[k1] >= 1 &&
          counts[k2] >= 1 &&
          counts[k3] >= 1) {
        counts[k1]--;
        counts[k2]--;
        counts[k3]--;
        _backtrack(
          counts,
          setsNeeded - 1,
          hasPair,
          current.withMentsu(Mentsu(MentsuType.shuntsu, firstKind)),
          results,
        );
        counts[k1]++;
        counts[k2]++;
        counts[k3]++;
      }
    }
  }
}
