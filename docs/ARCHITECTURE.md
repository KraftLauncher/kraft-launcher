# Architecture

This project splits code into features (e.g., `account`), where [each feature contains 3 layers](https://docs.flutter.dev/app-architecture/concepts#layered-architecture):

## `data`

Network requests, I/O operations, data sources, data classes, enums, and data types.

* **Usually returns raw data from APIs**, but may perform minor transformations or response mappings when needed—for example, in `checkMinecraftJavaOwnership` for simplicity.
* **Response data classes include only relevant fields**. Unused fields from APIs are not parsed and are silently ignored.
* **Data sources should be minimal, generic, and free of side effects or business logic.**  
Their responsibility is limited to low-level interactions with storage mechanisms (e.g., database, network, filesystem).  
For example, `readAccounts` in `FileAccountStorage` should simply return `null` if the file doesn’t exist, without creating it—even if that’s the intended behavior. Such logic should be handled in higher-level components like `AccountRepository`, which coordinates data sources and enforces application-specific rules.

### Example

The **data layer** should be exclusively responsible for data access, storage, and transformation.
It must avoid any business rules or decision-making related to how data is used or initialized.

#### ✅ Preferred

```dart
Future<FileAccounts?> readAccounts() async {
  if (!file.existsSync()) {
    return null;
  }

  final fileContent = (await file.readAsString()).trim();
  if (fileContent.isEmpty) {
    return null;
  }

  return FileAccounts.fromJson(jsonDecode(fileContent) as JsonObject);
}
```

#### 🚫 Avoid

```dart
Accounts loadAccounts() {
  Accounts saveEmpty() {
    final emptyAccounts = Accounts.empty();
    saveAccounts(emptyAccounts);
    return emptyAccounts;
  }

  if (!file.existsSync()) {
    // BAD: Read the explanation for details.
    return saveEmpty();
  }

  final fileContent = file.readAsStringSync().trim();
  if (fileContent.isEmpty) {
    // BAD: Read the explanation for details.
    return saveEmpty();
  }

  return Accounts.fromJson(jsonDecode(fileContent) as JsonObject);
}
```

**Explanation:**  
The data layer should not include any business logic such as creating or saving default data when none exists. Such decision-making — even if it aligns with the app’s intended behavior — belongs to the [`logic`](#logic) layer. Keeping the data layer focused purely on data retrieval and persistence ensures clear separation of concerns and easier maintainability.

#### Prefer dedicated data classes

It’s preferable to use separate data classes in the data layer instead of the business logic models.

External network services may evolve or break things and that should not
affect the entire app.

Similarly, storage representations might differ or evolve independently (e.g., for backward compatibility), so maintaining distinct data models for persistence ensures the business logic remains stable and focused on domain concepts.

## `logic`

Business logic and state management, usually depends on the data sources from the `data` layer.

* **Should not contain any I/O operations or network requests**, as this complicates mocking dependencies in unit tests. Such operations belong exclusively in the data layer.
* **Prefers separating business logic from state management** to simplify testing and allow actions without triggering state changes when needed in the UI.
* **Should not include UI-specific logic**, such as user error messages, icons or navigation.
* **Should avoid depending on Flutter-specific APIs (e.g., `BuildContext`) whenever possible.**  
Business logic should remain decoupled from the Flutter framework to improve testability and maintainability.  
In rare cases, using Flutter APIs is acceptable—primarily when integrating with platform-dependent plugins (e.g., [`shared_preferences`](https://pub.dev/packages/shared_preferences)). However, this should be avoided for plugins that perform UI-related tasks or navigation (e.g., [`url_launcher`](https://pub.dev/packages/url_launcher)) to keep the business logic layer free from UI dependencies.

### Example

**Coming soon.**

<!-- The example is commented as we're still evolving a few things. -->
<!-- The **logic layer** should be exclusively responsible for business rules and decision-making. It should not handle data retrieval/storage or UI-specific tasks like error messages or navigation with `BuildContext`.

It does not concern itself with where data comes from, how it is stored, or how it is presented.

#### ✅ Preferred

```dart
// IMPORTANT: This is just an example and doesn't follow best practices,
// doesn't work as expected.
class AccountManager {
  final MinecraftAccounts accounts;
  final FileAccountStorage fileAccountStorage;

  AccountManager(this.accounts, {required this.fileAccountStorage});

  bool canAddAccount(String username) {
    // Business rule: no duplicate usernames are allowed.
    return !accounts.list.any((account) => account.username == username);
  }

  MinecraftAccounts addAccount(String username) {
    if (!canAddAccount(username)) {
      throw UsernameTakenException();
    }

    final updatedAccounts = accounts.copyWith(
      list: [...accounts.list, Account(username: username)],
    );
    fileAccountStorage.saveAccounts(accounts);
    return updatedAccounts;
  }
}
```

#### 🚫 Avoid

```dart
import 'package:flutter/widgets.dart';

class AccountManager {
  final File file;

  AccountManager(this.file);

  // BAD: Avoid UI error handling, navigation or direct data access here
  MinecraftAccounts loadAndAddAccount(String username, BuildContext context) {
    final content = file.readAsStringSync();
    final accounts = MinecraftAccounts.fromJson(jsonDecode(content));
    
    if (accounts.list.any((account) => account.username == username)) {
      context.pop();
      throw Exception(context.loc.userExistsFailureMessage);
    }

    final updated = accounts.copyWith(
      list: [...accounts.list, Account(username: username)],
    );

    try {
      file.writeAsStringSync(jsonEncode(updated.toJson()));
    } on Exception catch(e) {
      throw Exception(context.loc.writeLocalFileFailed);
    }
    return updated;
  }
}
``` -->

## `ui`

Widgets and UI logic (e.g., localization, error messages).

* **Should not depend directly on the `data` layer**, even when no state is required. Instead, it should depend on a business logic-specific class (e.g., `AccountRepository`).

### Example

**Coming soon.**

> [!TIP]
> A feature is a group of related code inside a directory, one special exception is the `common` directory which contains common code
> to be used across different features.

This architecture is different from Uncle Bob's Clean Architecture. Clean Architecture follows stricter rules, has more abstractions, and is more generic. We also use fewer classes and avoid verbose suffixes like `DataSource` or `UseCase`.

## Resources

See also:

* [Bloc Architecture](https://bloclibrary.dev/architecture/)
* [Flutter App Architecture](https://docs.flutter.dev/app-architecture)
