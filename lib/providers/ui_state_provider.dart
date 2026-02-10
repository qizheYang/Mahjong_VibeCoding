import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../engine/tile/tile.dart';

class UiState {
  final Tile? selectedTile;
  final bool showRoundResult;

  const UiState({this.selectedTile, this.showRoundResult = false});

  UiState copyWith({
    Tile? Function()? selectedTile,
    bool? showRoundResult,
  }) {
    return UiState(
      selectedTile: selectedTile != null ? selectedTile() : this.selectedTile,
      showRoundResult: showRoundResult ?? this.showRoundResult,
    );
  }
}

class UiStateNotifier extends StateNotifier<UiState> {
  UiStateNotifier() : super(const UiState());

  void selectTile(Tile? tile) {
    state = state.copyWith(selectedTile: () => tile);
  }

  void showRoundResult() {
    state = state.copyWith(showRoundResult: true);
  }

  void hideRoundResult() {
    state = state.copyWith(showRoundResult: false, selectedTile: () => null);
  }
}

final uiStateProvider = StateNotifierProvider<UiStateNotifier, UiState>(
  (ref) => UiStateNotifier(),
);
