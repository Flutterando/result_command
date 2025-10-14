## 2.2.0

* ADDED: Stream support in `CommandRef`.

## 2.1.0
* ADDED: `filter` method for deriving transformed values from command states.
* ADDED: `CommandRef` class for listening to changes in `ValueListenables` and executing actions dynamically.
* DEPRECATED: Command state methods (`isIdle`, `isRunning`, etc.) moved to `CommandState` for better encapsulation.
* IMPROVED: Documentation for new features and deprecated methods.

## 2.0.0
* ADDED: Cache methods `getCachedSuccess()`, `getCachedFailure()`.
* ADDED: Improved documentation.
* ADDED: Bumped Dart SDK version.

## 1.3.0
* ADDED: Global observer command state listener.

## 1.2.0
* ADDED: `when` operator.

## 1.1.2
* FIXED: Documentation.

## 1.1.1
* FIXED: Documentation.

## 1.1.0
* ADDED: State history.
* ADDED: Timeout.
* ADDED: Cancellation support.
* ADDED: Command state getters.
* FIXED: Running class name.

## 1.0.0
* Initial release.
