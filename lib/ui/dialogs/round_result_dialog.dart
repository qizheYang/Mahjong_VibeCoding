import 'package:flutter/material.dart';
import '../../engine/tile/tile.dart';
import '../../engine/tile/tile_sort.dart';
import '../../engine/state/meld.dart';
import '../../engine/state/round_state.dart';
import '../../engine/state/game_state.dart';
import '../../engine/scoring/score_result.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Dialog showing the result of a completed round.
/// Layout modeled after Tenhou / Mahjong Soul result screens.
class RoundResultDialog extends StatelessWidget {
  final GameState gameState;
  final RoundState round;
  final ScoreResult? scoreResult;
  final List<int>? drawScoreChanges;
  final List<bool>? tenpaiList;
  final VoidCallback onContinue;

  const RoundResultDialog({
    super.key,
    required this.gameState,
    required this.round,
    this.scoreResult,
    this.drawScoreChanges,
    this.tenpaiList,
    required this.onContinue,
  });

  static const _handTileSize = TileSize(width: 24, height: 34);
  static const _doraTileSize = TileSize(width: 20, height: 28);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xE6192819),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: scoreResult != null ? _buildWinResult() : _buildDrawResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildWinResult() {
    final winner = round.players[round.winnerIndex!];
    final isMenzen = winner.melds.every((m) => !m.isOpen);
    final showUra = winner.isRiichi || winner.isDoubleRiichi;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === Win banner ===
        _buildWinBanner(),
        const SizedBox(height: 14),

        // === Winning hand ===
        _buildWinningHand(winner),
        const SizedBox(height: 10),

        // === Dora indicators ===
        _buildDoraRow('Dora', round.wall.doraIndicators, faceUp: true),
        if (showUra) ...[
          const SizedBox(height: 4),
          _buildDoraRow('Ura', round.wall.uraDoraIndicators, faceUp: true),
        ],
        const SizedBox(height: 14),

        // === Yaku + dora list ===
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Yaku entries
              ...scoreResult!.yakuList.map((yaku) => _yakuRow(
                    yaku.name,
                    '${yaku.han(isMenzen)} han',
                  )),
              // Dora entries
              if (scoreResult!.doraCount > 0)
                _yakuRow('Dora', '${scoreResult!.doraCount} han'),
              if (scoreResult!.uraDoraCount > 0)
                _yakuRow('Ura-dora', '${scoreResult!.uraDoraCount} han'),
              if (scoreResult!.redDoraCount > 0)
                _yakuRow('Red dora', '${scoreResult!.redDoraCount} han'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // === Score tier + total ===
        Text(
          scoreResult!.tierName,
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${scoreResult!.han} han  ${scoreResult!.fu} fu',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          _paymentText(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // === Score changes ===
        _buildScoreTable(),
        const SizedBox(height: 14),

        // === Continue button ===
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildDrawResult() {
    final isExhaustive = round.endReason == RoundEndReason.exhaustiveDraw;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Draw banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isExhaustive ? '流局' : 'Abortive Draw',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isExhaustive ? 'Exhaustive Draw' : '',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        // Tenpai/Noten status
        if (isExhaustive && tenpaiList != null) ...[
          const SizedBox(height: 14),
          _buildTenpaiStatus(),
        ],
        const SizedBox(height: 14),
        _buildScoreTable(),
        const SizedBox(height: 14),
        _buildContinueButton(),
      ],
    );
  }

  /// Shows tenpai/noten labels for each player.
  Widget _buildTenpaiStatus() {
    final windKanji = const ['東', '南', '西', '北'];
    final tenpaiNames = <String>[];
    final notenNames = <String>[];

    for (int i = 0; i < 4; i++) {
      final label = '${windKanji[round.players[i].seatWind]}${i == 0 ? "(You)" : ""}';
      if (tenpaiList![i]) {
        tenpaiNames.add(label);
      } else {
        notenNames.add(label);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          if (tenpaiNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('聴牌', style: TextStyle(color: Colors.greenAccent, fontSize: 13)),
                  Text(tenpaiNames.join('  '), style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                ],
              ),
            ),
          if (notenNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('不聴', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                  Text(notenNames.join('  '), style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Win type banner (Tsumo! or Ron!) with winner info.
  Widget _buildWinBanner() {
    final isTsumo = round.endReason == RoundEndReason.tsumo;
    final windKanji = const ['東', '南', '西', '北'];
    final winner = round.players[round.winnerIndex!];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isTsumo
                  ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                  : [const Color(0xFFC62828), const Color(0xFFE53935)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isTsumo ? 'Tsumo' : 'Ron',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${windKanji[winner.seatWind]}${round.winnerIndex == 0 ? " (You)" : ""}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  /// Display the winning hand: closed tiles | winning tile highlighted | melds.
  Widget _buildWinningHand(dynamic winner) {
    final isRon = round.endReason == RoundEndReason.ron;
    final winningTile = isRon ? round.lastDiscardedTile : winner.justDrew;

    // Closed hand tiles (excluding the winning tile for separation)
    List<Tile> closedTiles = List<Tile>.from(winner.hand as List<Tile>);
    if (isRon && round.lastDiscardedTile != null) {
      closedTiles.add(round.lastDiscardedTile!);
    }
    closedTiles = TileSort.sort(closedTiles);

    // Separate the winning tile from the rest for highlighting
    List<Tile> mainTiles;
    Tile? highlightTile;
    if (winningTile != null && closedTiles.contains(winningTile)) {
      mainTiles = List.from(closedTiles);
      mainTiles.remove(winningTile);
      highlightTile = winningTile;
    } else {
      mainTiles = closedTiles;
    }

    final melds = winner.melds as List<Meld>;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Main closed tiles
          ...mainTiles.map((tile) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: TileWidget(tile: tile, size: _handTileSize),
              )),
          // Winning tile with gap and highlight
          if (highlightTile != null) ...[
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: TileWidget(tile: highlightTile, size: _handTileSize),
            ),
          ],
          // Melds
          if (melds.isNotEmpty) ...[
            const SizedBox(width: 10),
            ...melds.map((meld) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: meld.tiles.map((tile) {
                      if (meld.type == MeldType.closedKan) {
                        final idx = meld.tiles.indexOf(tile);
                        if (idx == 0 || idx == 3) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: TileBack(size: _handTileSize),
                          );
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: TileWidget(tile: tile, size: _handTileSize),
                      );
                    }).toList(),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// A row of dora indicator tiles with a label.
  Widget _buildDoraRow(String label, List<Tile> indicators, {required bool faceUp}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
        ...indicators.map((tile) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: faceUp
                  ? TileWidget(tile: tile, size: _doraTileSize)
                  : TileBack(size: _doraTileSize),
            )),
      ],
    );
  }

  /// A single yaku entry row.
  Widget _yakuRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.amber, fontSize: 13)),
        ],
      ),
    );
  }

  /// Score table showing all 4 players with score changes.
  Widget _buildScoreTable() {
    final windKanji = const ['東', '南', '西', '北'];
    final changes = scoreResult?.payment.scoreChanges ?? drawScoreChanges;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: List.generate(4, (i) {
          final seatWind = round.players[i].seatWind;
          final score = gameState.scores[i];
          final change = changes?[i] ?? 0;
          final isYou = i == 0;
          final isWinner = i == round.winnerIndex;
          final isTenpai = tenpaiList != null && tenpaiList!.length > i && tenpaiList![i];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                // Wind + label
                SizedBox(
                  width: 70,
                  child: Text(
                    '${windKanji[seatWind]}${isYou ? " (You)" : ""}',
                    style: TextStyle(
                      color: isWinner
                          ? Colors.amber
                          : (isTenpai ? Colors.greenAccent : Colors.white70),
                      fontSize: 13,
                      fontWeight: (isWinner || isTenpai) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // Score
                Expanded(
                  child: Text(
                    '$score',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isWinner
                          ? Colors.amber
                          : (isTenpai ? Colors.greenAccent : Colors.white),
                      fontSize: 14,
                      fontWeight: (isWinner || isTenpai) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                // Change
                SizedBox(
                  width: 80,
                  child: Text(
                    change != 0
                        ? (change > 0 ? '(+$change)' : '($change)')
                        : '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: change > 0
                          ? Colors.greenAccent
                          : (change < 0 ? Colors.redAccent : Colors.white54),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Payment text (e.g., "8000", "4000/2000 all").
  String _paymentText() {
    final desc = scoreResult!.payment.description;
    return '${scoreResult!.payment.totalWinnerGain} pts ($desc)';
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          gameState.isGameOver ? '总结算' : 'Next Round',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
