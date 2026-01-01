/// Internal dependency tracking and batching utilities.
///
/// You typically don't need to use these directly, but they are exported
/// for advanced use-cases (custom widgets, debugging, or custom integration).
///
/// The key idea:
/// - During [RxView] build, we "track" which [FxSubscribable] values are read.
/// - We subscribe to them.
/// - When any changes, [RxView] rebuilds.
typedef FxVoidCallback = void Function();

/// Global tracker used by [RxView] and derived values.
class FxTracker {
  FxTracker._();

  static FxDependencyCollector? _currentCollector;

  /// Current dependency collector (set only during tracking).
  static FxDependencyCollector? get current => _currentCollector;

  /// Execute [fn] while recording dependencies into [collector].
  static T track<T>(FxDependencyCollector collector, T Function() fn) {
    final prev = _currentCollector;
    _currentCollector = collector;
    try {
      return fn();
    } finally {
      _currentCollector = prev;
    }
  }

  // -----------------------
  // Batching
  // -----------------------
  static int _batchDepth = 0;
  static final Set<FxVoidCallback> _batched = <FxVoidCallback>{};

  /// Whether we are currently batching notifications.
  static bool get isBatching => _batchDepth > 0;

  /// Group multiple writes into a single notify wave.
  static void batch(void Function() fn) {
    _batchDepth++;
    try {
      fn();
    } finally {
      _batchDepth--;
      if (_batchDepth == 0 && _batched.isNotEmpty) {
        final toRun = List<FxVoidCallback>.from(_batched);
        _batched.clear();
        for (final cb in toRun) cb();
      }
    }
  }

  /// Schedule a notification callback.
  ///
  /// If batching, the callback is queued and will be executed once at the end
  /// of the outer-most batch.
  static void schedule(FxVoidCallback cb) {
    if (isBatching) {
      _batched.add(cb);
    } else {
      cb();
    }
  }
}

/// Collects [FxSubscribable] dependencies during a tracked build/evaluation.
class FxDependencyCollector {
  FxDependencyCollector({required this.onInvalidate});

  final Set<FxSubscribable> _deps = <FxSubscribable>{};

  /// Called when any dependency changes.
  final FxVoidCallback onInvalidate;

  /// Add a dependency to the set.
  void add(FxSubscribable dep) => _deps.add(dep);

  /// Subscribe to all recorded dependencies.
  void subscribeAll() {
    for (final d in _deps) {
      d.subscribe(onInvalidate);
    }
  }

  /// Unsubscribe from all recorded dependencies.
  void unsubscribeAll() {
    for (final d in _deps) {
      d.unsubscribe(onInvalidate);
    }
  }

  /// Clear the recorded dependency set.
  void clear() => _deps.clear();
}

/// Base class for values that can be subscribed to.
///
/// Note: methods are intentionally public so subclasses in other files
/// can call them (Dart privacy is library-level).
abstract class FxSubscribable {
  final Set<FxVoidCallback> _listeners = <FxVoidCallback>{};

  /// Subscribe to notifications.
  void subscribe(FxVoidCallback cb) => _listeners.add(cb);

  /// Unsubscribe from notifications.
  void unsubscribe(FxVoidCallback cb) => _listeners.remove(cb);

  /// Notify all listeners (batch-safe).
  void notify() {
    if (_listeners.isEmpty) return;

    FxTracker.schedule(() {
      // Copy to avoid concurrent modification.
      final list = List<FxVoidCallback>.from(_listeners);
      for (final cb in list) cb();
    });
  }
}
