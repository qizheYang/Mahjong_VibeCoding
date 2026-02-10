import 'package:flutter/material.dart';
import '../../engine/state/meld.dart';
import '../tiles/tile_widget.dart';
import '../tiles/tile_back.dart';
import '../tiles/tile_size.dart';

/// Displays a player's declared melds.
class MeldDisplay extends StatelessWidget {
  final List<Meld> melds;
  final TileSize tileSize;

  const MeldDisplay({
    super.key,
    required this.melds,
    required this.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    if (melds.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: melds.map((meld) => _buildMeld(meld)).toList(),
    );
  }

  Widget _buildMeld(Meld meld) {
    return Padding(
      padding: EdgeInsets.only(left: tileSize.width * 0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: meld.tiles.map((tile) {
          if (meld.type == MeldType.closedKan) {
            // Show closed kan: first and last face-down, middle face-up
            final idx = meld.tiles.indexOf(tile);
            if (idx == 0 || idx == 3) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: tileSize.spacing / 2),
                child: TileBack(size: tileSize),
              );
            }
          }

          final isCalled = tile == meld.calledTile;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: tileSize.spacing / 2),
            child: TileWidget(
              tile: tile,
              size: tileSize,
              isSideways: isCalled,
            ),
          );
        }).toList(),
      ),
    );
  }
}
