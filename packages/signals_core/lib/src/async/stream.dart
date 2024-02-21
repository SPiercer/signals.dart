import 'dart:async';

import '../core/signals.dart';
import 'signal.dart';
import 'state.dart';

/// A [Signal] that stores value in [AsyncState] and
/// fetches data from a [Stream]
class StreamSignal<T> extends AsyncSignal<T> {
  late final Computed<Stream<T>> _stream;
  bool _fetching = false;
  StreamSubscription<T>? _subscription;
  final void Function()? _onDone;
  bool _done = false;
  EffectCleanup? _cleanup;

  /// Check if the signal is done
  bool get isDone => _done;

  /// Cancel the subscription on error
  final bool? cancelOnError;

  /// List of dependencies to recompute the stream
  final List<ReadonlySignal<dynamic>> dependencies;

  /// First value of the stream
  Future<T> get last => _stream.value.last;

  /// Last value of the stream
  Future<T> get first => _stream.value.first;

  /// A [Signal] that stores value in [AsyncState] and
  /// fetches data from a [Stream]
  StreamSignal(
    Stream<T> Function() callback, {
    this.cancelOnError,
    super.debugLabel,
    super.equality,
    T? initialValue,
    this.dependencies = const [],
    void Function()? onDone,
    bool lazy = true,
    super.autoDispose,
  })  : _onDone = onDone,
        super(initialValue != null
            ? AsyncState.data(initialValue)
            : AsyncState.loading()) {
    _stream = computed(
      () {
        for (final dep in dependencies) {
          dep.value;
        }
        return callback();
      },
      equality: identical,
    );
    if (!lazy) value;
  }

  /// Execute the stream
  Future<void> execute(Stream<T> src) async {
    if (_done || _fetching) return;
    _fetching = true;
    _subscription = src.listen(
      setValue,
      onError: setError,
      onDone: _finish,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> _finish() async {
    _done = true;
    _onDone?.call();
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Check if the subscription is paused
  bool get isPaused => _subscription?.isPaused ?? false;

  /// Pause the subscription
  void pause([Future<void>? resume]) {
    _subscription?.pause(resume);
    set(value, force: true);
  }

  /// Resume the subscription
  void resume() {
    _subscription?.resume();
    set(value, force: true);
  }

  /// Cancel the subscription
  Future<void> cancel() async {
    await _finish();
  }

  @override
  Future<void> reload() async {
    super.reload();
    _stream.recompute();
    _fetching = false;
    _done = false;
    _subscription?.cancel();
    _subscription = null;
    await execute(_stream.value);
  }

  @override
  Future<void> refresh() async {
    super.refresh();
    _stream.recompute();
    _fetching = false;
    _done = false;
    _subscription?.cancel();
    _subscription = null;
    await execute(_stream.value);
  }

  @override
  void reset([AsyncState<T>? value]) {
    super.reset(value);
    _fetching = false;
    _done = false;
    _subscription?.cancel();
    _subscription = null;
    init();
  }

  @override
  void dispose() {
    super.dispose();
    _cleanup?.call();
    _subscription?.cancel();
  }

  @override
  AsyncState<T> get value {
    _cleanup ??= _stream.subscribe((src) {
      reset();
      execute(src);
    });
    return super.value;
  }

  @override
  void setError(Object error, [StackTrace? stackTrace]) {
    super.setError(error, stackTrace);
    if (cancelOnError == true) {
      _finish();
    }
  }
}

/// Create a [StreamSignal] from a [Stream]
StreamSignal<T> streamSignal<T>(
  Stream<T> Function() callback, {
  T? initialValue,
  String? debugLabel,
  List<ReadonlySignal<dynamic>> dependencies = const [],
  SignalEquality<AsyncState<T>>? equality,
  void Function()? onDone,
  bool? cancelOnError,
  bool lazy = true,
  bool autoDispose = false,
}) {
  return StreamSignal(
    callback,
    initialValue: initialValue,
    debugLabel: debugLabel,
    dependencies: dependencies,
    equality: equality,
    onDone: onDone,
    cancelOnError: cancelOnError,
    lazy: lazy,
    autoDispose: autoDispose,
  );
}
