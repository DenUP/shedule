extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    Iterator<T> it = iterator;
    if (!it.moveNext()) {
      return null;
    }
    return it.current;
  }

  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
