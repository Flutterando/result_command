import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:result_dart/functions.dart';
import 'package:result_dart/result_dart.dart';

part 'command_ref.dart';
part 'history.dart';
part 'states.dart';
part 'types.dart';

void Function(CommandState state)? _defaultObserverListener;

/// Represents a generic command with lifecycle and execution.
///
/// This class supports state management, notifications, and execution
/// with optional cancellation and history tracking.
sealed class Command<T extends Object> extends ChangeNotifier
    with CommandHistoryManager<T>
    implements ValueListenable<CommandState<T>> {
  /// Callback executed when the command is cancelled.
  final void Function()? onCancel;

  Command([this.onCancel, int maxHistoryLength = 10]) : super() {
    initializeHistoryManager(maxHistoryLength);
    _setValue(IdleCommand<T>(), metadata: {'reason': 'Command created'});
  }

  /// Sets the default observer listener for all commands.
  /// This listener is called whenever the state of any command changes.
  /// This can be useful for logging, debugging, or global state management.
  static void setObserverListener(void Function(CommandState state) listener) {
    _defaultObserverListener = listener;
  }

  /// The current state of the command.
  CommandState<T> _value = IdleCommand<T>();

  SuccessCommand<T>? _cachedSuccessCommand;
  FailureCommand<T>? _cachedFailureCommand;

  /// Returns the cached value of the [SuccessCommand], or `null` if not found.
  ///
  /// This method retrieves the value associated with a successful command execution
  /// from the cache. If the command is not a [SuccessCommand], it returns `null`.
  T? getCachedSuccess() => _cachedSuccessCommand?.value;

  /// Returns the cached exception of the [FailureCommand], or `null` if not found.
  ///
  /// This method retrieves the exception associated with a failed command execution
  /// from the cache. If the command is not a [FailureCommand], it returns `null`.
  Exception? getCachedFailure() => _cachedFailureCommand?.error;

  ///[isIdle]: Checks if the command is in the idle state.
  @Deprecated('Use value.isIdle instead')
  bool get isIdle => value.isIdle;

  ///[isRunning]: Checks if the command is currently running.
  @Deprecated('Use value.isRunning instead')
  bool get isRunning => value.isRunning;

  ///[isCancelled]: Checks if the command has been cancelled.
  @Deprecated('Use value.isCancelled instead')
  bool get isCancelled => value.isCancelled;

  ///[isSuccess]: Checks if the command execution was successful.
  @Deprecated('Use value.isSuccess instead')
  bool get isSuccess => value.isSuccess;

  ///[isFailure]: Checks if the command execution failed.
  @Deprecated('Use value.isFailure instead')
  bool get isFailure => value.isFailure;

  @override
  CommandState<T> get value => _value;

  /// Filters the current command state and returns a ValueListenable with the transformed value.
  ///
  /// This method allows you to derive a new value from the command's state using a transformation function.
  /// The resulting ValueListenable updates whenever the command's state changes.
  ///
  /// - [defaultValue]: The initial value for the ValueListenable.
  /// - [func]: A function that takes the current CommandState and returns the transformed value.
  ///
  /// Returns a ValueListenable that emits the transformed value whenever the command's state changes.
  ///
  /// Example:
  /// ```dart
  /// final filteredValue = command.filter<String>(
  ///   'Default Value',
  ///   (state) {
  ///     if (state is SuccessCommand<String>) {
  ///       return 'Success: ${state.value}';
  ///     } else if (state is FailureCommand<String>) {
  ///       return 'Error: ${state.error}';
  ///     }
  ///     return null; // Ignore other states.
  ///   },
  /// );
  ///
  /// filteredValue.addListener(() {
  ///   print('Filtered Value: ${filteredValue.value}');
  /// });
  /// ```
  ValueListenable<W> filter<W>(
          W defaultValue, W? Function(CommandState<T>) func) =>
      _FilteredValueNotifier<W, T>(defaultValue, this, func);

  /// Cancels the execution of the command.
  ///
  /// If the command is in the [RunningCommand] state, the [onCancel] callback is invoked,
  /// and the state transitions to [CancelledCommand].
  void cancel({Map<String, dynamic>? metadata}) {
    if (value.isRunning) {
      try {
        onCancel?.call();
      } catch (e) {
        _setValue(FailureCommand<T>(e is Exception ? e : Exception('$e')),
            metadata: metadata);
        return;
      }
      _setValue(CancelledCommand<T>(),
          metadata: metadata ?? {'reason': 'Manually cancelled'});
    }
  }

  /// Resets the command state to [IdleCommand].
  ///
  /// This clears the current state, allowing the command to be reused.
  void reset({Map<String, dynamic>? metadata}) {
    if (value.isRunning) {
      return;
    }
    _cachedFailureCommand = null;
    _cachedSuccessCommand = null;
    _setValue(IdleCommand<T>(),
        metadata: metadata ?? {'reason': 'Command reset'});
  }

  /// Adds a listener that executes specific callbacks based on command state changes.
  ///
  /// This method provides a convenient way to listen to command state changes and react
  /// with appropriate callbacks. Each state has its corresponding optional callback, and if no
  /// callback is provided for the current state, the [orElse] callback will be executed if provided.
  ///
  /// The listener will be triggered immediately with the current state, and then every time
  /// the command state changes.
  ///
  /// Returns a [VoidCallback] that can be called to remove the listener.
  ///
  /// Example:
  /// ```dart
  /// final command = Command0<String>(() async {
  ///   return Success('Hello, World!');
  /// });
  ///
  /// final removeListener = command.addWhenListener(
  ///   onIdle: () => print('Command is ready'),
  ///   onRunning: () => print('Command is executing'),
  ///   onSuccess: (value) => print('Success: $value'),
  ///   onFailure: (error) => print('Error: $error'),
  ///   onCancelled: () => print('Command was cancelled'),
  ///   orElse: () => print('Unknown state'),
  /// );
  ///
  /// // Later, remove the listener
  /// removeListener();
  /// ```
  VoidCallback addWhenListener({
    void Function()? onIdle,
    void Function()? onRunning,
    void Function(T value)? onSuccess,
    void Function(Exception? exception)? onFailure,
    void Function()? onCancelled,
    void Function()? orElse,
  }) {
    void listener() {
      switch (value) {
        case IdleCommand<T>():
          (onIdle ?? orElse)?.call();
        case CancelledCommand<T>():
          (onCancelled ?? orElse)?.call();
        case RunningCommand<T>():
          (onRunning ?? orElse)?.call();
        case FailureCommand<T>(:final error):
          onFailure != null ? onFailure(error) : orElse?.call();
        case SuccessCommand<T>(:final value):
          onSuccess != null ? onSuccess(value) : orElse?.call();
      }
    }

    // Execute immediately with current state
    listener();

    // Add listener for future state changes
    addListener(listener);

    // Return a function to remove the listener
    return () => removeListener(listener);
  }

  /// Executes the given [action] and updates the command state accordingly.
  ///
  /// The state transitions to [RunningCommand] during execution,
  /// and to either [SuccessCommand] or [FailureCommand] upon completion.
  ///
  /// Optionally accepts a [timeout] duration to limit the execution time of the action.
  /// If the action times out, the command is cancelled and transitions to [FailureCommand].
  Future<void> _execute(CommandAction0<T> action, {Duration? timeout}) async {
    if (value.isRunning) {
      return;
    } // Prevent multiple concurrent executions.
    _setValue(RunningCommand<T>(), metadata: {'status': 'Execution started'});
    bool hasError = false;

    late Result<T> result;
    try {
      if (timeout != null) {
        result = await action().timeout(timeout, onTimeout: () {
          cancel(metadata: {'reason': 'Execution timed out'});
          return Failure<T, Exception>(Exception("Command timed out"));
        });
      } else {
        result = await action();
      }
    } catch (e, stackTrace) {
      hasError = true;
      _setValue(FailureCommand<T>(Exception('Unexpected error: $e')),
          metadata: {'error': '$e', 'stackTrace': stackTrace.toString()});
      return;
    } finally {
      if (!hasError) {
        final newValue = result
            .map(SuccessCommand<T>.new)
            .mapError(FailureCommand<T>.new)
            .fold(identity, identity);
        if (value.isRunning) {
          _setValue(newValue);
        }
      }
    }
  }

  /// Updates the cache whenever the command state changes.
  void _updateCache(CommandState<T> newValue) {
    if (newValue is SuccessCommand<T>) {
      _cachedSuccessCommand = newValue;
    } else if (newValue is FailureCommand<T>) {
      _cachedFailureCommand = newValue;
    }
  }

  /// Sets the current state of the command and notifies listeners.
  ///
  /// Additionally, records the change in the state history with optional metadata
  /// and updates the cache.
  void _setValue(CommandState<T> newValue, {Map<String, dynamic>? metadata}) {
    if (newValue.instanceName == _value.instanceName &&
        stateHistory.isNotEmpty) {
      return;
    }
    _value = newValue;
    _updateCache(newValue);
    _defaultObserverListener?.call(newValue);
    addHistoryEntry(CommandHistoryEntry(state: newValue, metadata: metadata));
    notifyListeners();
  }
}

/// A command that executes an action without any arguments.
final class Command0<T extends Object> extends Command<T> {
  /// The action to be executed.
  final CommandAction0<T> _action;

  /// Creates a [Command0] with the specified [action] and optional [onCancel] callback.
  Command0(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action and updates the command state.
  Future<void> execute({Duration? timeout}) async {
    await _execute(() => _action(), timeout: timeout);
  }
}

/// A command that executes an action with one argument.
final class Command1<T extends Object, A> extends Command<T> {
  /// The action to be executed.
  final CommandAction1<T, A> _action;

  /// Creates a [Command1] with the specified [action] and optional [onCancel] callback.
  Command1(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action with the given [argument] and updates the command state.
  Future<void> execute(A argument, {Duration? timeout}) async {
    await _execute(() => _action(argument), timeout: timeout);
  }
}

/// A command that executes an action with two arguments.
final class Command2<T extends Object, A, B> extends Command<T> {
  /// The action to be executed.
  final CommandAction2<T, A, B> _action;

  /// Creates a [Command2] with the specified [action] and optional [onCancel] callback.
  Command2(this._action, {void Function()? onCancel, int maxHistoryLength = 10})
      : super(onCancel, maxHistoryLength);

  /// Executes the action with the given [argument1] and [argument2],
  /// and updates the command state.
  Future<void> execute(A argument1, B argument2, {Duration? timeout}) async {
    await _execute(() => _action(argument1, argument2), timeout: timeout);
  }
}

final class _FilteredValueNotifier<W, T extends Object>
    extends ValueNotifier<W> {
  final ValueListenable<CommandState<T>> _command;
  final W? Function(CommandState<T>) _func;

  _FilteredValueNotifier(super.defaultValue, this._command, this._func) {
    _command.addListener(_updateValue);
  }

  void _updateValue() {
    final newValue = _func(_command.value);
    if (newValue != null) {
      value = newValue;
    }
  }

  @override
  void dispose() {
    _command.removeListener(_updateValue);
    super.dispose();
  }
}
