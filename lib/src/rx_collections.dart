/// Reactive collections.
///
/// These are minimal wrappers around Dart collections that notify dependents
/// on mutation. Reading properties like [length] is auto-tracked.
///
/// Notes:
/// - If you mutate objects *inside* the collection, call `refresh()` to notify.
import 'tracker.dart';

class RxList<T> extends FxSubscribable {
  RxList([Iterable<T>? initial])
      : _list = initial != null ? List<T>.from(initial) : <T>[];

  final List<T> _list;

  int get length {
    FxTracker.current?.add(this);
    return _list.length;
  }

  bool get isEmpty {
    FxTracker.current?.add(this);
    return _list.isEmpty;
  }

  bool get isNotEmpty {
    FxTracker.current?.add(this);
    return _list.isNotEmpty;
  }

  T operator [](int index) {
    FxTracker.current?.add(this);
    return _list[index];
  }

  /// Returns an unmodifiable snapshot.
  List<T> toList() {
    FxTracker.current?.add(this);
    return List<T>.unmodifiable(_list);
  }

  void add(T value) {
    _list.add(value);
    notify();
  }

  void addAll(Iterable<T> values) {
    _list.addAll(values);
    notify();
  }

  void insert(int index, T value) {
    _list.insert(index, value);
    notify();
  }

  void removeAt(int index) {
    _list.removeAt(index);
    notify();
  }

  bool remove(Object? value) {
    final ok = _list.remove(value);
    if (ok) notify();
    return ok;
  }

  void clear() {
    if (_list.isEmpty) return;
    _list.clear();
    notify();
  }

  void refresh() => notify();
}

class RxMap<K, V> extends FxSubscribable {
  RxMap([Map<K, V>? initial])
      : _map = initial != null ? Map<K, V>.from(initial) : <K, V>{};

  final Map<K, V> _map;

  int get length {
    FxTracker.current?.add(this);
    return _map.length;
  }

  bool get isEmpty {
    FxTracker.current?.add(this);
    return _map.isEmpty;
  }

  bool get isNotEmpty {
    FxTracker.current?.add(this);
    return _map.isNotEmpty;
  }

  V? operator [](K key) {
    FxTracker.current?.add(this);
    return _map[key];
  }

  Iterable<K> get keys {
    FxTracker.current?.add(this);
    return _map.keys;
  }

  Map<K, V> toMap() {
    FxTracker.current?.add(this);
    return Map<K, V>.unmodifiable(_map);
  }

  void operator []=(K key, V value) {
    _map[key] = value;
    notify();
  }

  V? remove(K key) {
    final existed = _map.containsKey(key);
    final v = _map.remove(key);
    if (existed) notify();
    return v;
  }

  void clear() {
    if (_map.isEmpty) return;
    _map.clear();
    notify();
  }

  void refresh() => notify();
}

class RxSet<T> extends FxSubscribable {
  RxSet([Iterable<T>? initial])
      : _set = initial != null ? Set<T>.from(initial) : <T>{};

  final Set<T> _set;

  int get length {
    FxTracker.current?.add(this);
    return _set.length;
  }

  bool contains(Object? value) {
    FxTracker.current?.add(this);
    return _set.contains(value);
  }

  Set<T> toSet() {
    FxTracker.current?.add(this);
    return Set<T>.unmodifiable(_set);
  }

  bool add(T value) {
    final ok = _set.add(value);
    if (ok) notify();
    return ok;
  }

  bool remove(Object? value) {
    final ok = _set.remove(value);
    if (ok) notify();
    return ok;
  }

  void clear() {
    if (_set.isEmpty) return;
    _set.clear();
    notify();
  }

  void refresh() => notify();
}
