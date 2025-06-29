# Architecture

![Layered architecture](https://docs.flutter.dev/assets/images/docs/app-architecture/common-architecture-concepts/horizontal-layers-with-icons.png)

> [!TIP]
> A feature is a group of related code inside a directory, one special exception is the `common` directory which contains common code
> to be used across different features.

This project follows layer architecture and splits code into features (e.g., `account`), where [each feature contains 3 layers](https://docs.flutter.dev/app-architecture/concepts#layered-architecture):

## `data`

Data sources (e.g., Network requests, File I/O operations, Databases), data classes, enums, and data types.

* **Usually returns raw data from APIs**, but may perform minor transformations or response mappings when needed—for example, in `checkMinecraftJavaOwnership` for simplicity.
* **Response data classes may contain only relevant fields**. Sometimes, unused fields from external APIs are not fully parsed and are silently ignored.
* **Data sources should be minimal, generic, and free of side effects or business logic.**  
Their responsibility is limited to low-level interactions with storage mechanisms (e.g., database, network, filesystem).  
For example, `readAccounts` in `FileAccountStorage` should simply return `null` if the file doesn’t exist, without creating it—even if that’s the intended behavior. Such logic should be handled in higher-level components like `AccountRepository`, which coordinates data sources and enforces application-specific rules.
<!-- TODO: I'm considering to change this to move entities from data to logic layer. However, I'm not considering this for MinecraftVersionManifest and related classes as they are too many (and will be * 2). Need more consideration. Update this bellow with the table if this was ever done. -->
* **Usually contains both entities and models.**  
  * A **model** represents data structures specific to a data source, also known as DTOs (Data Transfer Objects). It may include serialization and deserialization logic (e.g., from JSON). Data sources typically return models.  
  * An **entity** represents the business logic and rules of the application and is not tied to any data source. If an external API changes its structure, only the related model needs to be updated—not the entity. Entities are often used by the [`logic`](#logic) and [`ui`](#ui).

| Layer     | Uses Entities? | Uses Models? | Why? |
|-----------|----------------|--------------|------|
| **Data**  | ❌ No           | ✅ Yes        | Models represent raw data from data sources (e.g., API, DB, etc). |
| **Logic** | ✅ Yes          | ✅ Sometimes  | Work with entities for clean business logic to stay independent from the data sources. May map models from the data sources to entities. |
| **UI**    | ✅ Yes          | ❌ No         | UI displays domain concepts, not raw API data. The UI is independent of the data sources. |


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

  return FileAccounts.fromJson(jsonDecode(fileContent) as Map<String, Object?>);
}
```

#### 🚫 Avoid

```dart
Accounts loadAccounts() {
  Accounts saveEmpty() {
    final emptyAccounts = Accounts.empty();
    // BAD: Depends on `saveAccounts` which in the same class as `loadAccounts`, mocking in unit tests will be slightly harder.
    saveAccounts(emptyAccounts);
    return emptyAccounts;
  }

  if (!file.existsSync()) {
    return saveEmpty();
  }

  final fileContent = file.readAsStringSync().trim();
  if (fileContent.isEmpty) {
    return saveEmpty();
  }

  return Accounts.fromJson(jsonDecode(fileContent) as Map<String, Object?>);
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

Business logic, usually depends on the data sources from the `data` layer.

* **Should not contain any I/O operations or network requests**, as this complicates mocking dependencies in unit tests. Such operations belong exclusively in the data layer.
* **Should not include UI-specific logic**, such as user error messages, icons, navigation or state management (e.g., Flutter blocs/cubits).
* **Flutter blocs/cubits are part of the [`ui`](#ui), not this layer.**  
Which can be [confusing due to the name BLoC (Business Logic Components)](https://taej0127.medium.com/the-biggest-problem-of-bloc-is-the-name-bloc-1ba1522be5e2). These components typically [respond to input from the presentation layer (i.e., widgets) by emitting new states](https://bloclibrary.dev/architecture/#business-logic-layer). The blocs/cubits serve as [state holders](https://developer.android.com/topic/architecture#ui-layer) or controllers for widgets, [similar to how Android ViewModels are used](https://developer.android.com/topic/libraries/architecture/viewmodel).
* **Should avoid depending on Flutter-specific APIs (e.g., `BuildContext`) whenever possible.**  
Business logic should remain decoupled from the Flutter framework to improve testability and maintainability.  
In rare cases, using Flutter APIs is acceptable—primarily when integrating with platform-dependent plugins (e.g., [`shared_preferences`](https://pub.dev/packages/shared_preferences)). However, this should be avoided for plugins that perform UI-related tasks or navigation (e.g., [`url_launcher`](https://pub.dev/packages/url_launcher)) to keep the business logic layer free from UI dependencies.

This layer is optional and is not always required, see also:

* https://docs.flutter.dev/app-architecture/guide#optional-domain-layer
* https://developer.android.com/topic/architecture#domain-layer

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

Widgets, UI logic (e.g., localization, error messages) and state management (e.g., Flutter blocs/cubits).

* **Should not depend directly on data sources from the `data` layer**, even when no state is required. Instead, it should depend on a business logic-specific class (e.g., `AccountRepository`).
* **Prefers separating business logic from state management** to simplify testing and allow actions without triggering state changes when needed in the UI. Such logic belongs to the [`logic`](#logic) layer.

### Example

**Coming soon.**

## Clean Architecture?

This architecture is different from [Uncle Bob's Clean Architecture](https://en.wikipedia.org/wiki/Robert_C._Martin). Clean Architecture follows stricter rules, has more abstractions, and is more generic. We also use fewer classes and avoid verbose suffixes like `DataSource` or `UseCase`. We prefer names like `VersionManifestFetcher` rather than `GetVersionManifestUseCase`.

## Resources

See also:

* [Bloc Architecture Guide](https://bloclibrary.dev/architecture/)
* [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture)
* [Android App Architecture Guide](https://developer.android.com/topic/architecture)
