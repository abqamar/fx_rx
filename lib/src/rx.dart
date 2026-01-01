/// Reactive value for any Dart type.
///
/// Reading [value] inside an [RxView] (or inside [computed]) automatically
/// registers this instance as a dependency.
///
/// Writing to [value] notifies all dependents.
///
/// Example:
/// ```dart
/// final count = Rx(0);
///
/// RxView(() => Text("Count: ${count.value}"));
///
/// count.value++;
/// ```
import 'tracker.dart';

/// A simple disposer returned by manual listeners and effects.
class FxDisposer {
  FxDisposer(this._dispose);

  final void Function() _dispose;
  bool _done = false;

  void dispose() {
    if (_done) return;
    _done = true;
    _dispose();
  }
}

class Rx<T> extends FxSubscribable {
  Rx(this._value);

  T _value;

  /// Get current value (auto-tracked if inside [FxTracker.track]).
  T get value {
    FxTracker.current?.add(this);
    return _value;
  }

  /// Set value; notifies listeners if changed.
  set value(T v) {
    if (identical(_value, v) || _value == v) return;
    _value = v;
    notify();
  }

  /// Force notify (useful when mutating inner fields of objects).
  void refresh() => notify();

  /// Manual subscription (useful outside widgets).
  ///
  /// Returns a [FxDisposer] to stop listening.
  FxDisposer listen(void Function(T value) fn, {bool fireImmediately = false}) {
    void handler() => fn(_value);
    subscribe(handler);
    if (fireImmediately) fn(_value);
    return FxDisposer(() => unsubscribe(handler));
  }

  @override
  String toString() => 'Rx<$T>($_value)';
}

/// Sugar extensions:
/// ```dart
/// final name = "A".rx; // Rx<String>
/// final age = 10.rx;   // Rx<int>
/// ```
extension FxRxExt<T> on T {
  Rx<T> get rx => Rx<T>(this);
}
