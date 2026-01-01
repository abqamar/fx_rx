/// Derived reactive values.
///
/// A computed value automatically tracks any reactive dependencies used inside
/// its computation and updates when they change.
///
/// Computed values are lazy:
/// - they compute the first time you read [value]
/// - they recompute automatically when dependencies change
///
/// Example:
/// ```dart
/// final first = "A".rx;
/// final last  = "B".rx;
///
/// final full = computed(() => "${first.value} ${last.value}");
///
/// RxView(() => Text(full.value));
/// ```
import 'tracker.dart';

/// Factory function to create a computed value.
FxComputed<T> computed<T>(T Function() compute) => FxComputed<T>(compute);

class FxComputed<T> extends FxSubscribable {
  FxComputed(this._compute);

  final T Function() _compute;

  T? _cached;
  bool _hasValue = false;
  bool _dirty = true;

  late final FxDependencyCollector _collector = FxDependencyCollector(
    onInvalidate: () {
      // When any dependency changes:
      // 1) mark dirty
      // 2) notify dependents of this computed value
      _dirty = true;
      notify();
    },
  );

  /// Get the computed value (auto-tracked if inside [FxTracker.track]).
  T get value {
    // Track this computed itself as a dependency if read during RxView build.
    FxTracker.current?.add(this);

    if (_dirty || !_hasValue) {
      _recompute();
    }
    return _cached as T;
  }

  void _recompute() {
    // Rebuild dependencies:
    _collector.unsubscribeAll();
    _collector.clear();

    final v = FxTracker.track(_collector, () => _compute());
    _cached = v;
    _hasValue = true;
    _dirty = false;

    // Subscribe to new dependencies:
    _collector.subscribeAll();
  }

  /// Force recompute on next read.
  void invalidate() {
    _dirty = true;
    notify();
  }

  /// Cleanup subscriptions if you create a long-lived computed that you want to
  /// dispose explicitly. Most of the time you can ignore this.
  void dispose() {
    _collector.unsubscribeAll();
    _collector.clear();
  }

  @override
  String toString() =>
      _hasValue ? 'FxComputed<$T>($_cached)' : 'FxComputed<$T>(<lazy>)';
}
