import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/readonly.dart';
import '../core/signal.dart';

/// Signal notifier widget
class SignalProvider<T extends FlutterReadonlySignal>
    extends SingleChildStatelessWidget {
  /// Signal notifier widget
  const SignalProvider({
    super.key,
    required T Function() create,
    // required this.notifier,
    required super.child,
  })  : _create = create,
        notifier = null;

  final T Function()? _create;

  /// A constructor for `SignalProvider` that takes an existing notifier.
  ///
  /// This constructor allows you to provide an existing notifier instance
  /// to the `SignalProvider`. The `create` parameter is required and should
  /// be the notifier instance you want to provide. The `child` parameter is
  /// also required and represents the widget subtree that will have access
  /// to the notifier.
  ///
  /// Example usage:
  /// ```dart
  /// SignalProvider.value(
  ///   create: myNotifier,
  ///   child: MyChildWidget(),
  /// );
  /// ```
  ///
  /// - `create`: The existing notifier instance to be provided.
  /// - `child`: The widget subtree that will have access to the notifier.
  const SignalProvider.value({
    super.key,
    required T value,
    required super.child,
  })  : notifier = value,
        _create = null;

  /// The notifier that holds the value of type [T]. i.e the signal
  final T? notifier;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '$runtimeType used outside of MultiBlocProvider must specify a child',
    );
    final value = notifier;
    if (value == null) {
      return InheritedProvider<T>(
        create: (_) => _create!(),
        dispose: (_, signal) => signal.dispose(),
        startListening: _startListening,
        lazy: true,
        child: child,
      );
    } else {
      return InheritedProvider<T>.value(
        value: value,
        startListening: _startListening,
        lazy: true,
        child: child,
      );
    }
  }

  static VoidCallback _startListening(
    InheritedContext e,
    FlutterReadonlySignal value,
  ) =>
      value.subscribe((_) => e.markNeedsNotifyDependents());

  /// Find signal in widget tree
  static T? of<T extends FlutterSignal>(
    BuildContext context, {
    bool listen = true,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    } on Exception {
      rethrow;
    }
  }
}
