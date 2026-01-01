/// Effect helpers.
///
/// Effects are optional utilities to run side-effects when values change.
/// Always dispose an effect when it is no longer needed.
///
/// Included:
/// - [ever]      : runs on every change
/// - [once]      : runs only on the first change
/// - [debounce]  : runs after changes stop for a duration
/// - [interval]  : runs at most once per duration (throttling)
/// - [batch]     : group multiple writes into a single notify wave
import 'dart:async';

import 'rx.dart';
import 'tracker.dart';

/// Run [fn] whenever [rx] changes.
/// Returns a disposer to stop listening.
FxDisposer ever<T>(Rx<T> rx, void Function(T value) fn,
    {bool fireImmediately = false}) {
  return rx.listen(fn, fireImmediately: fireImmediately);
}

/// Run [fn] only once.
///
/// By default, it triggers on the *first change* after subscription.
/// If [fireImmediately] is true, it triggers immediately with the current value
/// and then disposes itself.
FxDisposer once<T>(Rx<T> rx, void Function(T value) fn,
    {bool fireImmediately = false}) {
  FxDisposer? disposer;

  if (fireImmediately) {
    fn(rx.value);
    return FxDisposer(() {});
  }

  disposer = rx.listen((v) {
    fn(v);
    disposer?.dispose();
  });

  return FxDisposer(() => disposer?.dispose());
}

/// Debounce changes: wait for [duration] after the last change, then run [fn].
///
/// Useful for search-as-you-type.
///
/// Example:
/// ```dart
/// final query = "".rx;
/// final d = debounce(query, const Duration(milliseconds: 300), (v) => search(v));
/// d.dispose();
/// ```
FxDisposer debounce<T>(Rx<T> rx, Duration duration, void Function(T value) fn,
    {bool fireImmediately = false}) {
  Timer? timer;
  late final FxDisposer sub;

  void schedule(T v) {
    timer?.cancel();
    timer = Timer(duration, () => fn(v));
  }

  if (fireImmediately) {
    schedule(rx.value);
  }

  sub = rx.listen((v) => schedule(v));

  return FxDisposer(() {
    timer?.cancel();
    sub.dispose();
  });
}

/// Interval/throttle: run [fn] at most once per [duration].
///
/// If changes happen faster than [duration], they are ignored until the window
/// elapses.
///
/// Example:
/// ```dart
/// final scroll = 0.0.rx;
/// final d = interval(scroll, const Duration(milliseconds: 200), (v) => log(v));
/// d.dispose();
/// ```
FxDisposer interval<T>(Rx<T> rx, Duration duration, void Function(T value) fn,
    {bool fireImmediately = false}) {
  Timer? gate;
  bool open = true;

  void trigger(T v) {
    if (!open) return;
    open = false;
    fn(v);
    gate?.cancel();
    gate = Timer(duration, () => open = true);
  }

  if (fireImmediately) {
    trigger(rx.value);
  }

  final sub = rx.listen(trigger);

  return FxDisposer(() {
    gate?.cancel();
    sub.dispose();
  });
}

/// Group multiple writes into a single notify wave.
void batch(void Function() fn) => FxTracker.batch(fn);
