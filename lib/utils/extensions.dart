extension ListExtensions<T> on List<T> {
  /// Returns a new list with the element at [index] removed.
  List<T> withoutAt(int index) {
    return [...sublist(0, index), ...sublist(index + 1)];
  }

  /// Returns a new list with [element] removed (first occurrence).
  List<T> without(T element) {
    final i = indexOf(element);
    if (i == -1) return List.from(this);
    return withoutAt(i);
  }

  /// Returns a new list with [element] appended.
  List<T> withAppended(T element) {
    return [...this, element];
  }

  /// Returns a new list with [element] inserted at [index].
  List<T> withInserted(int index, T element) {
    return [...sublist(0, index), element, ...sublist(index)];
  }

  /// Returns a new list with the element at [index] replaced by [element].
  List<T> withReplaced(int index, T element) {
    return [...sublist(0, index), element, ...sublist(index + 1)];
  }
}

extension IntIterableExtensions on Iterable<int> {
  int get sum => fold(0, (a, b) => a + b);
}
