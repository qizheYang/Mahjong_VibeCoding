import '../tile/tile.dart';

enum AbortReason { kyuushuKyuuhai, suufonRenda, suuchaRiichi, suukaikan, sanchaHou }

/// All possible player actions in the game.
sealed class PlayerAction {
  final int playerIndex;
  const PlayerAction(this.playerIndex);
}

class DiscardAction extends PlayerAction {
  final Tile tile;
  final bool declareRiichi;

  const DiscardAction(super.playerIndex, this.tile, {this.declareRiichi = false});

  @override
  String toString() => 'Discard(p$playerIndex, $tile${declareRiichi ? ", riichi" : ""})';
}

class ChiAction extends PlayerAction {
  final Tile calledTile;
  final Tile handTile1;
  final Tile handTile2;

  const ChiAction(super.playerIndex, {
    required this.calledTile,
    required this.handTile1,
    required this.handTile2,
  });

  @override
  String toString() => 'Chi(p$playerIndex, $calledTile + $handTile1, $handTile2)';
}

class PonAction extends PlayerAction {
  final Tile calledTile;
  final Tile handTile1;
  final Tile handTile2;

  const PonAction(super.playerIndex, {
    required this.calledTile,
    required this.handTile1,
    required this.handTile2,
  });

  @override
  String toString() => 'Pon(p$playerIndex, $calledTile)';
}

class OpenKanAction extends PlayerAction {
  final Tile calledTile;
  final List<Tile> handTiles;

  const OpenKanAction(super.playerIndex, {
    required this.calledTile,
    required this.handTiles,
  });

  @override
  String toString() => 'OpenKan(p$playerIndex, $calledTile)';
}

class ClosedKanAction extends PlayerAction {
  final int tileKind;

  const ClosedKanAction(super.playerIndex, this.tileKind);

  @override
  String toString() => 'ClosedKan(p$playerIndex, kind=$tileKind)';
}

class AddedKanAction extends PlayerAction {
  final Tile addedTile;
  final int meldIndex;

  const AddedKanAction(super.playerIndex, {
    required this.addedTile,
    required this.meldIndex,
  });

  @override
  String toString() => 'AddedKan(p$playerIndex, $addedTile -> meld $meldIndex)';
}

class TsumoAction extends PlayerAction {
  const TsumoAction(super.playerIndex);

  @override
  String toString() => 'Tsumo(p$playerIndex)';
}

class RonAction extends PlayerAction {
  const RonAction(super.playerIndex);

  @override
  String toString() => 'Ron(p$playerIndex)';
}

class SkipAction extends PlayerAction {
  const SkipAction(super.playerIndex);

  @override
  String toString() => 'Skip(p$playerIndex)';
}

class AbortAction extends PlayerAction {
  final AbortReason reason;

  const AbortAction(super.playerIndex, this.reason);

  @override
  String toString() => 'Abort(p$playerIndex, $reason)';
}
