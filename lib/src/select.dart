/// Select (distinct derived) reactive values.
///
/// [select] is similar to [computed], but it only notifies dependents when the
/// selected value actually changes (using `==` or a custom [equals]).
///
/// This is useful to prevent unnecessary rebuilds when you're only interested
/// in a small part of a larger state.
///
/// Example:
/// ```dart
/// final user = Rx(User(name: "A", age: 1));
///
/// // Only rebuild when age changes:
/// final age = select(() => user.value.age);
///
/// RxView(() => Text("Age: ${age.value}"));
/// ```
import 'tracker.dart';

/// Create a distinct derived value.
///
/// The [selector] may read any reactive values. Dependencies are tracked
/// automatically.
FxSelected<T> select<T>(
  T Function() selector, {
  bool Function(T a, T b)? equals,
}) =>
    FxSelected<T>(selector, equals: equals);

class FxSelected<T> extends FxSubscribable {
  FxSelected(this._selector, {bool Function(T a, T b)? equals})
      : _equals = equals ?? _defaultEquals {
    _rebuildSubscriptionsAndComputeInitial();
  }

  final T Function() _selector;
  final bool Function(T a, T b) _equals;

  late final FxDependencyCollector _collector = FxDependencyCollector(
    onInvalidate: _onDepChanged,
  );

  T? _cached;
  bool _hasValue = false;

  static bool _defaultEquals<T>(T a, T b) => a == b;

  /// Current selected value (auto-tracked).
  T get value {
    FxTracker.current?.add(this);
    if (!_hasValue) {
      _rebuildSubscriptionsAndComputeInitial();
    }
    return _cached as T;
  }

  void _onDepChanged() {
    // Dependency changed: recompute now and notify ONLY if selected changes.
    final next = _computeWithTracking();
    if (_hasValue && _equals(_cached as T, next)) {
      // no change -> do nothing (prevents rebuild)
      return;
    }
    _cached = next;
    _hasValue = true;
    notify();
  }

  void _rebuildSubscriptionsAndComputeInitial() {
    _collector.unsubscribeAll();
    _collector.clear();

    final v = _computeWithTracking();
    _cached = v;
    _hasValue = true;

    _collector.subscribeAll();
  }

  T _computeWithTracking() {
    return FxTracker.track(_collector, () => _selector());
  }

  /// Dispose to remove dependency subscriptions.
  void dispose() {
    _collector.unsubscribeAll();
    _collector.clear();
  }

  @override
  String toString() =>
      _hasValue ? 'FxSelected<$T>($_cached)' : 'FxSelected<$T>(<lazy>)';
}
