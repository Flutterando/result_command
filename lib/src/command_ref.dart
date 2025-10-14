part of 'command.dart';

typedef CommandRefAction0<W> = W Function(Reference ref);

/// Represents a command that listens to changes in one or more ValueListenables and executes an action.
///
/// The `CommandRef` class allows you to define a reference function (`ref`) that derives values from
/// `ValueListenables`. These values are then passed to the action for execution whenever the `ValueListenables` change.
///
/// - [CommandRefAction0]: A function that derives values from `ValueListenables`.
/// - [CommandAction1]: The action to be executed based on the derived values.
///
/// Example:
/// ```dart
/// final listenable = ValueNotifier<int>(0);
///
/// final commandRef = CommandRef<int, int>(
///   (ref) => ref(listenable),
///   (value) async => Success(value * 2),
/// );
///
/// commandRef.addListener(() {
///   final status = commandRef.value;
///   if (status is SuccessCommand<int>) {
///     print('Result: ${status.value}');
///   }
/// });
///
/// listenable.value = 5; // Executes the command with the value 5.
/// ```
///
/// Features:
/// - Automatically listens to changes in `ValueListenables`.
/// - Executes the action whenever the derived value changes.
/// - Cleans up listeners when disposed.
final class CommandRef<T extends Object, W> extends Command<T> {
  /// The reference function that derives values from ValueListenables.
  final CommandRefAction0<W> _refAction;

  /// The action to be executed based on the derived values.
  final CommandAction1<T, W> _action;

  late final Reference _ref;

  /// Creates a CommandRef with the specified reference function and action.
  CommandRef(this._refAction, this._action) {
    _ref = Reference(_innerExecute);
    _refAction(_ref);
  }

  /// Executes the action based on the derived values.
  Future<void> _innerExecute() {
    return _execute(() => _action(_refAction(_ref)));
  }

  /// Disposes the CommandRef and cleans up listeners.
  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }
}

class Reference {
  final Future<void> Function() _innerExecute;
  final _disposers = <void Function()>[];
  final _innerValueNotifiers = <ValueNotifier>[];
  final _executionQueue = <Future<void> Function()>[];

  var _innerValueNotifiersCount = 0;
  var _isProcessingQueue = false;

  Reference(this._innerExecute);

  V call<V>(ValueListenable<V> listenable) {
    _disposers.add(() => listenable.removeListener(_enqueueExecution));
    listenable.addListener(_enqueueExecution);
    return listenable.value;
  }

  V stream<V>(Stream<V> stream, V initialValue) {
    final notifier = _innerValueNotifiers.length > _innerValueNotifiersCount
        ? _innerValueNotifiers[_innerValueNotifiersCount] as ValueNotifier<V>
        : ValueNotifier<V>(initialValue);

    if (_innerValueNotifiers.length <= _innerValueNotifiersCount) {
      _innerValueNotifiers.add(notifier);
      final subscription = stream.listen((event) {
        notifier.value = event;
      });

      _disposers.add(() {
        subscription.cancel();
      });

      _innerValueNotifiersCount++;
      return call(notifier);
    }

    _innerValueNotifiersCount++;

    return notifier.value;
  }

  void _enqueueExecution() {
    _executionQueue.add(() async {
      _innerValueNotifiersCount = 0;
      await _innerExecute();
    });

    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_executionQueue.isNotEmpty) {
      final execute = _executionQueue.removeAt(0);
      await execute();
    }

    _isProcessingQueue = false;
  }

  void dispose() {
    _executionQueue.clear();

    for (final disposer in _disposers) {
      disposer();
    }

    _innerValueNotifiers.clear();
    _disposers.clear();
  }
}
