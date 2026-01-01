import 'package:flutter/material.dart';
import 'package:fx_rx/fx_rx.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: DemoPage());
  }
}

class DemoStore {
  final count = 0.rx;
  final query = "".rx;
  final items = RxList<String>();
  final users = RxAsync<List<String>>();

  late final doubled = computed(() => count.value * 2);
  late final itemCount = select(() => items.length);

  void inc() => count.value++;

  Future<void> loadUsers() async {
    await users.run(() async {
      await Future.delayed(const Duration(seconds: 1));
      return ["Alice", "Bob", "Charlie"];
    });
  }
}

final store = DemoStore();

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Effects (dispose not needed here because this page is long-lived in the demo).
    // In real apps, keep the disposer and dispose it when appropriate.
    once(store.count, (v) => debugPrint("First count change: $v"));
    debounce(store.query, const Duration(milliseconds: 400),
        (v) => debugPrint("Search: $v"));
    interval(store.count, const Duration(seconds: 1),
        (v) => debugPrint("Interval count: $v"));

    return Scaffold(
      appBar: AppBar(title: const Text("fx_rx example")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RxView(() => Text("Count: ${store.count.value}",
                style: const TextStyle(fontSize: 20))),
            RxView(() => Text("Doubled: ${store.doubled.value}")),
            RxView(() => Text("Items: ${store.itemCount.value}")),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                    onPressed: store.inc, child: const Text("Increment")),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () =>
                      store.items.add("Item ${store.items.length + 1}"),
                  child: const Text("Add item"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration:
                  const InputDecoration(labelText: "Search (debounced)"),
              onChanged: (v) => store.query.value = v,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: store.loadUsers, child: const Text("Load users")),
            const SizedBox(height: 12),
            RxView(
              () => store.users.when(
                idle: () => const Text("Idle"),
                loading: () => const CircularProgressIndicator(),
                data: (d) => Text("Users: ${d.join(", ")}"),
                error: (e) => Text("Error: $e"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
