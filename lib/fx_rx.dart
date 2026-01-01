/// fx_rx
///
/// A tiny reactive state management library for Flutter.
///
/// Main exports:
/// - [Rx] reactive value
/// - [RxView] widget that rebuilds when tracked dependencies change
/// - [RxList], [RxMap], [RxSet] reactive collections
/// - [computed] derived reactive value
/// - [RxAsync] async state container (loading/data/error)
/// - [ever] effect helper
/// - [batch] group updates to avoid multiple notify waves
library fx_rx;

export 'src/tracker.dart';
export 'src/rx.dart';
export 'src/rx_collections.dart';
export 'src/rx_view.dart';
export 'src/effects.dart';
export 'src/computed.dart';
export 'src/async.dart';
export 'src/select.dart';
