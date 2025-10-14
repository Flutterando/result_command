part of 'command.dart';

/// A function that defines a command action with no arguments.
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction0<T extends Object> = AsyncResult<T> Function();

/// A function that defines a command action with one argument of type [A].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction1<T extends Object, A> = AsyncResult<T> Function(A);

/// A function that defines a command action with two arguments of types [A] and [B].
/// The action returns an [AsyncResult] of type [T].
typedef CommandAction2<T extends Object, A, B> = AsyncResult<T> Function(A, B);
