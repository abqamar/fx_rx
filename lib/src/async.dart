/// Async reactive state container.
///
/// [RxAsync] represents one of these states:
/// - idle (default)
/// - loading
/// - data
/// - error
///
/// It is designed to be simple and UI-friendly.
///
/// Example:
/// ```dart
/// final users = RxAsync<List<User>>();
///
/// await users.run(() => api.fetchUsers());
///
/// RxView(() => users.when(
///   idle: () => const Text("Idle"),
///   loading: () => const CircularProgressIndicator(),
///   data: (d) => Text("Users: ${d.length}"),
///   error: (e) => Text("$e"),
/// ));
/// ```
import 'tracker.dart';

enum RxAsyncStatus { idle, loading, data, error }

class RxAsync<T> extends FxSubscribable {
  RxAsync({T? initialData}) {
    if (initialData != null) {
      _status = RxAsyncStatus.data;
      _data = initialData;
    }
  }

  RxAsyncStatus _status = RxAsyncStatus.idle;
  T? _data;
  Object? _error;
  StackTrace? _stackTrace;

  /// Current status (auto-tracked).
  RxAsyncStatus get status {
    FxTracker.current?.add(this);
    return _status;
  }

  /// Latest data (auto-tracked).
  T? get data {
    FxTracker.current?.add(this);
    return _data;
  }

  /// Latest error (auto-tracked).
  Object? get error {
    FxTracker.current?.add(this);
    return _error;
  }

  /// Latest stackTrace (auto-tracked).
  StackTrace? get stackTrace {
    FxTracker.current?.add(this);
    return _stackTrace;
  }

  bool get isIdle => status == RxAsyncStatus.idle;
  bool get isLoading => status == RxAsyncStatus.loading;
  bool get hasData => status == RxAsyncStatus.data;
  bool get hasError => status == RxAsyncStatus.error;

  /// Set to idle and clear error (keeps data by default).
  void setIdle({bool clearData = false}) {
    _status = RxAsyncStatus.idle;
    _error = null;
    _stackTrace = null;
    if (clearData) _data = null;
    notify();
  }

  /// Set to loading (keeps previous data by default).
  void setLoading({bool clearError = true}) {
    _status = RxAsyncStatus.loading;
    if (clearError) {
      _error = null;
      _stackTrace = null;
    }
    notify();
  }

  /// Set data and mark status as data.
  void setData(T value) {
    _data = value;
    _error = null;
    _stackTrace = null;
    _status = RxAsyncStatus.data;
    notify();
  }

  /// Set error and mark status as error.
  void setError(Object error, [StackTrace? st]) {
    _error = error;
    _stackTrace = st;
    _status = RxAsyncStatus.error;
    notify();
  }

  /// Run an async task and update state automatically.
  ///
  /// - sets loading
  /// - awaits the result
  /// - sets data on success
  /// - sets error on failure
  Future<T> run(Future<T> Function() task,
      {bool keepPreviousData = true}) async {
    setLoading(clearError: true);
    if (!keepPreviousData) _data = null;

    try {
      final v = await task();
      setData(v);
      return v;
    } catch (e, st) {
      setError(e, st);
      rethrow;
    }
  }

  /// Pattern-match helper for UI.
  ///
  /// Provide handlers for the states you care about.
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error) error,
  }) {
    switch (status) {
      case RxAsyncStatus.idle:
        return idle();
      case RxAsyncStatus.loading:
        return loading();
      case RxAsyncStatus.data:
        final d = this.data;
        if (d == null) {
          // Rare case: data state but null data; treat as idle.
          return idle();
        }
        return data(d);
      case RxAsyncStatus.error:
        return error(this.error ?? Exception('Unknown error'));
    }
  }

  @override
  String toString() =>
      'RxAsync<$T>(status=$status, data=$_data, error=$_error)';
}
