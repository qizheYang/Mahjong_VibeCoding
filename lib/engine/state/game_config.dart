class GameConfig {
  final bool isHanchan;
  final int startingScore;
  final bool useRedDora;
  final int targetScore;

  const GameConfig({
    this.isHanchan = true,
    this.startingScore = 25000,
    this.useRedDora = true,
    this.targetScore = 30000,
  });

  /// Total number of rounds in the wind rotation (4 per wind).
  int get totalWinds => isHanchan ? 2 : 1;

  GameConfig copyWith({
    bool? isHanchan,
    int? startingScore,
    bool? useRedDora,
    int? targetScore,
  }) {
    return GameConfig(
      isHanchan: isHanchan ?? this.isHanchan,
      startingScore: startingScore ?? this.startingScore,
      useRedDora: useRedDora ?? this.useRedDora,
      targetScore: targetScore ?? this.targetScore,
    );
  }
}
