import '../tile/tile.dart';
import 'meld.dart';

/// Events emitted by the game engine for UI display and logging.
sealed class GameEvent {
  const GameEvent();
}

class TileDealtEvent extends GameEvent {
  final int playerIndex;
  final Tile tile;
  const TileDealtEvent(this.playerIndex, this.tile);
}

class TileDrawnEvent extends GameEvent {
  final int playerIndex;
  final Tile tile;
  final bool fromDeadWall;
  const TileDrawnEvent(this.playerIndex, this.tile, {this.fromDeadWall = false});
}

class TileDiscardedEvent extends GameEvent {
  final int playerIndex;
  final Tile tile;
  final bool isRiichi;
  const TileDiscardedEvent(this.playerIndex, this.tile, {this.isRiichi = false});
}

class CallMadeEvent extends GameEvent {
  final int playerIndex;
  final Meld meld;
  const CallMadeEvent(this.playerIndex, this.meld);
}

class RiichiDeclaredEvent extends GameEvent {
  final int playerIndex;
  const RiichiDeclaredEvent(this.playerIndex);
}

class TsumoEvent extends GameEvent {
  final int playerIndex;
  const TsumoEvent(this.playerIndex);
}

class RonEvent extends GameEvent {
  final int winnerIndex;
  final int loserIndex;
  const RonEvent(this.winnerIndex, this.loserIndex);
}

class DoraRevealedEvent extends GameEvent {
  final Tile indicator;
  const DoraRevealedEvent(this.indicator);
}

class ExhaustiveDrawEvent extends GameEvent {
  final List<bool> tenpaiPlayers;
  const ExhaustiveDrawEvent(this.tenpaiPlayers);
}

class AbortiveDrawEvent extends GameEvent {
  final String reason;
  const AbortiveDrawEvent(this.reason);
}

class RoundStartEvent extends GameEvent {
  final int roundWind;
  final int roundNumber;
  final int dealerIndex;
  const RoundStartEvent(this.roundWind, this.roundNumber, this.dealerIndex);
}
