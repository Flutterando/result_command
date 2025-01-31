
# <center>Result Command</center>

**Result Command** is a lightweight package that brings the **Command Pattern** to Flutter, allowing you to encapsulate actions, track their execution state, and manage results with clarity. Perfect for simplifying complex workflows, ensuring robust error handling, and keeping your UI reactive.

<center>

[![Version](https://img.shields.io/github/v/release/Flutterando/result_command?style=plastic)](https://pub.dev/packages/result_command)
[![Pub Points](https://img.shields.io/pub/points/result_command?label=pub%20points&style=plastic)](https://pub.dev/packages/result_command/score)
[![Flutterando Analysis](https://img.shields.io/badge/style-flutterando__analysis-blueviolet?style=plastic)](https://pub.dev/packages/flutterando_analysis/)

[![Pub Publisher](https://img.shields.io/pub/publisher/result_command?style=plastic)](https://pub.dev/publishers/flutterando.com.br/packages)

</center>

---

## Table of Contents

- [Getting Started](#getting-started)
- [Why Use Result Command?](#why-use-result-command)
- [How It Works](#how-it-works)
- [Command State (`CommandState`)](#command-state-commandstate)
  - [Accessing the State](#accessing-the-state)
  - [Reacting to State Changes](#reacting-to-state-changes)
- [State History (`CommandHistory`)](#state-history-commandhistory)
  - [Configuring the History](#configuring-the-history)
  - [Accessing the History](#accessing-the-history)
- [Getters for State Checks](#getters-for-state-checks)
- [Examples](#examples)
  - [Example 1: Simple Command with No Arguments](#example-1-simple-command-with-no-arguments)
  - [Example 2: Simple Command with Timeout](#example-2-simple-command-with-timeout)
  - [Example 3: Command with Arguments](#example-3-command-with-arguments)
  - [Example 4: Binding State to the UI](#example-4-binding-state-to-the-ui)
  - [Example 5: Cancellation](#example-5-cancellation)
  - [Example 5: using the map function](#example-5-using-the-map-function)
  - [Minimal Usage: Handling Only Success State and orElse](#minimal-usage-handling-only-success-state-and-orelse)
- [Benefits for Your Team](#benefits-for-your-team)
- [Contribute](#contribute)

---

## Getting Started

1. Add the package to your `pubspec.yaml`:

   ```yaml
   dependencies:
     result_command: x.x.x
     result_dart: 2.x.x
   ```

2. Wrap your actions in commands:
   - Use pre-defined `Command` types to encapsulate your logic.
   - Attach listeners to update your UI dynamically.

3. Execute commands from your UI and enjoy the benefits of encapsulated logic and state tracking.

---

## Why Use Result Command?

1. **Encapsulation**: Wrap your business logic into reusable commands.
2. **State Tracking**: Automatically manage states like `Idle`, `Running`, `Success`, `Failure`, and `Cancelled`.
3. **Error Handling**: Centralize how you handle successes and failures using the intuitive `Result` API.
4. **State History**: Track state transitions with optional metadata.
5. **Timeout Support**: Specify execution time limits for commands.
6. **Cancellation Support**: Cancel long-running tasks when needed.
7. **UI Integration**: React to command state changes directly in your Flutter widgets.

---

## How It Works

At its core, **Result Command** lets you define reusable actions (commands) that manage their lifecycle. Each command:

- **Executes an action** (e.g., API call, user input validation).
- **Tracks its state** (`Idle`, `Running`, etc.).
- **Notifies listeners** when the state changes.
- **Maintains a history** of states and transitions.
- **Returns a result** (`Success` or `Failure`) using the `Result` API.

---

## Command State (`CommandState`)

Each `Command` exposes its current state through a `CommandState`. The state represents one of the following:

- **`IdleCommand`**: The command is ready to execute.
- **`RunningCommand`**: The command is currently executing an action.
- **`SuccessCommand`**: The action completed successfully.
- **`FailureCommand`**: The action failed with an error.
- **`CancelledCommand`**: The action was explicitly stopped.

### Accessing the State

You can access the current state using the `value` property of the command:

```dart
final command = Command0<String>(() async {
  return Success('Hello, World!');
});

// The current state of the command.
print(command.value); // Outputs: SuccessCommand<String>
```

### Reacting to State Changes

The state updates automatically as the command executes:

- Use `addListener` for manual handling.
- Use `ValueListenableBuilder` to bind the state to your UI.

## State History (`CommandHistory`)

Each command tracks a configurable history of its states, useful for debugging, auditing, and behavioral analysis.

### Configuring the History

Set the maximum length of the history when creating a command:

```dart
final command = Command0<String>(
  () async => const Success('Done'),
  maxHistoryLength: 5,
);
```

### Accessing the History

Access the history with `stateHistory`:

```dart
final history = command.stateHistory;
history.forEach(print);
```

---

## Getters for State Checks

To simplify state management and improve code readability, the following getters are available:

- **`isIdle`**: Checks if the command is in the idle state.

  ```dart
  bool get isIdle => value is IdleCommand<T>;
  ```

- **`isRunning`**: Checks if the command is currently running.

  ```dart
  bool get isRunning => value is RunningCommand<T>;
  ```

- **`isCancelled`**: Checks if the command has been cancelled.

  ```dart
  bool get isCancelled => value is CancelledCommand<T>;
  ```

- **`isSuccess`**: Checks if the command execution was successful.

  ```dart
  bool get isSuccess => value is SuccessCommand<T>;
  ```

- **`isFailure`**: Checks if the command execution failed.

  ```dart
  bool get isFailure => value is FailureCommand<T>;
  ```

These getters allow you to write cleaner and more intuitive code when interacting with commands in your views or controllers.

---

## Examples

### Example 1: Simple Command with No Arguments

Encapsulate a simple action into a reusable `Command`:

```dart
final fetchGreetingCommand = Command0<String>(
  () async {
    await Future.delayed(Duration(seconds: 2));
    return Success('Hello, World!');
  },
);

fetchGreetingCommand.addListener(() {
  final snapshot = fetchGreetingCommand.value;
  if (snapshot is Success<String>) {
    final result = snapshot.value;
    print('Success: $result');
  } else if (snapshot is FailureCommand<String>) {
    final error = snapshot.error;
    print('Failure: $error');
  }
});

// Execute the command
fetchGreetingCommand.execute();
```

---

### Example 2: Simple Command with Timeout

Commands now support a timeout for execution:

```dart
final fetchGreetingCommand = Command0<String>(
  () async {
    await Future.delayed(Duration(seconds: 5)); // Simulating a delay.
    return Success('Hello, World!');
  },
);

fetchGreetingCommand //
      .execute(timeout: Duration(seconds: 2))
      .catchError((error) {
          print('Error: $error'); // "Error: Command timed out"
      },
);
```

---

### Example 3: Command with Arguments

Pass input to your command's action:

```dart
final calculateSquareCommand = Command1<int, int>(
  (number) async {
    if (number < 0) {
      return Failure(Exception('Negative numbers are not allowed.'));
    }
    return Success(number * number);
  },
);

calculateSquareCommand.addListener(() {
  final snapshot = calculateSquareCommand.value;
  if (snapshot is SuccessCommand<int>) {
    final result = snapshot.value;
    print('Square: $result');
  } else if (snapshot is FailureCommand<int>) {
    final error = snapshot.error;
    print('Error: $error');
  }
});

// Execute the command with input
calculateSquareCommand.execute(4);
```

---

### Example 4: Binding State to the UI

Use `ValueListenableBuilder` to update the UI automatically:

```dart
final loginCommand = Command2<bool, String, String>(
  (username, password) async {
    if (username == 'admin' && password == 'password') {
      return Success(true);
    }
    return Failure(Exception('Invalid credentials.'));
  },
);

Widget build(BuildContext context) {
  return Column(
    children: [
      ValueListenableBuilder<CommandState<bool>>(
        valueListenable: loginCommand,
        builder: (context, state, child) {
          if (state is RunningCommand<bool>) {
            return CircularProgressIndicator();
          } else if (state is SuccessCommand<bool>) {
            return Text('Login Successful!');
          } else if (state is FailureCommand<bool>) {
            return Text('Login Failed: ${(state as FailureCommand).error}');
          }
          return ElevatedButton(
            onPressed: () => loginCommand.execute('admin', 'password'),
            child: Text('Login'),
          );
        },
      ),
    ],
  );
}
```

---

### Example 5: Cancellation

Cancel long-running commands gracefully:

```dart

Isolate? _uploadIsolate;

void _uploadAction() {
  //  uploading code...
}

final uploadCommand = Command0<void>(
  () async {
    _uploadIsolate = await Isolate.spawn(_uploadAction, []);
  },
  onCancel: () {
   _uploadIsolate.kill();
  },
);

// Start the upload
uploadCommand.execute();

// Cancel after 3 seconds
Future.delayed(Duration(seconds: 3), () {
  uploadCommand.cancel();
});
```

---

### Example 5: using the map function

Cancel long-running commands gracefully:

```dart

final calculateSquareCommand = Command1<int, int>(
      (number) async {
    if (number < 0) {
      return Failure(Exception('Negative numbers are not allowed.'));
    }
    return Success(number * number);
  },
);

calculateSquareCommand.addListener(() {
    final message = calculateSquareCommand.value.when<String>(
        data: (value) => 'Square: $value',
        failure: (exception) => 'Error: ${exception?.message}',
        running: () => 'Calculating...',
        orElse: () => 'default value',
    );

    // Display the message in a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
    );
});
// Execute the command with input
calculateSquareCommand.execute(4);
```

```dart

Widget build(BuildContext context) {
  return Column(
    children: [
      ValueListenableBuilder<CommandState<bool>>(
        valueListenable: loginCommand,
        builder: (context, state, child) {
          return state.when(
            data: (_) => const Text('Login Successful!'),
            running: () => const CircularProgressIndicator(),
            failure: (error) => Text('Login Failed: $error'),
            orElse: () => ElevatedButton(
              onPressed: () => loginCommand.execute('admin', 'password'),
              child: Text('Login'),
            ),
          );
        },
      ),
    ],
  );
}
```

#### Minimal Usage: Handling Only Success State and orElse

```dart

final calculateSquareCommand = Command1<int, int>(
      (number) async {
    if (number < 0) {
      return Failure(Exception('Negative numbers are not allowed.'));
    }
    return Success(number * number);
  },
);

calculateSquareCommand.addListener(() {
    final message = calculateSquareCommand.value.when<String>(
        data: (value) => 'Square: $value',
        orElse: () => 'default value',
    );

    // Display the message in a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
    );
});
// Execute the command with input
calculateSquareCommand.execute(4);
```

#### **Notes**

- The function ensures type safety by requiring `data to handle the`success` state explicitly.
- The `orElse` callback is useful for dealing with unexpected states or adding default behavior.

---

## Benefits for Your Team

- **Simplified Collaboration**: Encapsulation makes it easier for teams to work independently on UI and business logic.
- **Reusability**: Commands can be reused across different widgets or flows.
- **Maintainability**: Cleaner separation of concerns reduces technical debt.

---

## Contribute

We’d love your help in improving **Result Command**! Feel free to report issues, suggest features, or submit pull requests.

---
