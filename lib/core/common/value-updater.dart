class ValueUpdater<T> {
  final T Function(T oldValue, T newValue) onUpdate;
  T value;
  T lastResult;

  ValueUpdater(this.onUpdate, {this.value});

  T update(T newValue) {
    T updated = onUpdate(value, newValue);
    value = newValue;
    lastResult = updated;
    return updated;
  }

  T check(T newValue) => onUpdate(value, newValue);
}
