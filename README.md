# fx_rx

A tiny reactive state management library for Flutter.

[![pub package](https://img.shields.io/pub/v/fx_rx.svg)](https://pub.dev/packages/fx_rx)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- `Rx<T>`: reactive value for any type
- `RxView(() => Widget)`: rebuilds automatically when `Rx` values used inside change
- `RxList`, `RxMap`, `RxSet`: reactive collections
- `computed(() => ...)`: derived reactive values that update automatically
- `select(() => ...)`: distinct derived values (notifies only when selected value changes)
- `RxAsync<T>`: simple async state (loading / data / error)
- Effects: `ever(rx, ...)`, `once(rx, ...)`, `debounce(rx, ...)`, `interval(rx, ...)`
- `batch(() { ... })`: group multiple writes into a single notify wave

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  fx_rx: ^0.0.1
```

## Quick start

```dart
import 'package:fx_rx/fx_rx.dart';

final count = Rx(0);

RxView(() => Text("Count: ${count.value}"));

void increment() => count.value++;
```

### Extensions

```dart
final name = "John".rx; // Rx<String>
final age  = 30.rx;      // Rx<int>
```

## Derived state (computed)

```dart
final first = "John".rx;
final last  = "Cena".rx;

final fullName = computed(() => "${first.value} ${last.value}");

RxView(() => Text(fullName.value));
```

## Async state (RxAsync)

```dart
final users = RxAsync<List<String>>();

Future<void> load() async {
  await users.run(() async {
    await Future.delayed(const Duration(seconds: 1));
    return ["A", "B", "C"];
  });
}

RxView(() => users.when(
  idle: () => const Text("Idle"),
  loading: () => const CircularProgressIndicator(),
  data: (d) => Text("Users: ${d.length}"),
  error: (e) => Text("Error: $e"),
));
```

## Reactive collections

```dart
final items = RxList<String>();

items.add("A");

RxView(() => Text("Total: ${items.length}"));
```

## Effects

```dart
final disposer = ever(count, (v) {
  // do something when count changes
});

disposer.dispose(); // stop listening
```

## Batch

```dart
batch(() {
  a.value = 1;
  b.value = 2;
});
```

## License

MIT. See `LICENSE`.


## Select (distinct derived)

```dart
final user = Rx({"name": "A", "age": 1});

// Only rebuild when "age" changes:
final age = select(() => user.value["age"]);

RxView(() => Text("Age: ${age.value}"));
```

## More effects

### once

```dart
final d = once(count, (v) {
  // runs once on first change
});
d.dispose();
```

### debounce

```dart
final d = debounce(query, const Duration(milliseconds: 300), (v) => search(v));
d.dispose();
```

### interval

```dart
final d = interval(scroll, const Duration(milliseconds: 200), (v) => log(v));
d.dispose();
```


## Example app

A runnable Flutter example is included in `example/`.

```bash
cd example
flutter run
```
