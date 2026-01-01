/// Reactive widget.
///
/// [RxView] rebuilds whenever any `Rx` / reactive collection / computed value
/// that is *read* during its build changes.
///
/// Example:
/// ```dart
/// final count = Rx(0);
///
/// RxView(() => Text("${count.value}"));
/// ```
import 'package:flutter/widgets.dart';
import 'tracker.dart';

typedef RxWidgetBuilder = Widget Function();

class RxView extends StatefulWidget {
  const RxView(this.builder, {super.key});

  final RxWidgetBuilder builder;

  @override
  State<RxView> createState() => _RxViewState();
}

class _RxViewState extends State<RxView> {
  late FxDependencyCollector _collector;

  @override
  void initState() {
    super.initState();
    _collector = FxDependencyCollector(onInvalidate: _invalidate);
  }

  void _invalidate() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _collector.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resubscribe every build based on what was read this time.
    _collector.unsubscribeAll();
    _collector.clear();

    return FxTracker.track(_collector, () {
      final w = widget.builder();
      _collector.subscribeAll();
      return w;
    });
  }
}
