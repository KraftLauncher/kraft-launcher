# Architecture

![Layered architecture](https://docs.flutter.dev/assets/images/docs/app-architecture/common-architecture-concepts/horizontal-layers-with-icons.png)

This project follows the [layered architecture](https://docs.flutter.dev/app-architecture/concepts#layered-architecture) and splits code into features (e.g., `account`), where each feature contains 3 layers ([`ui`](#ui), [`logic`](#logic) and [`data`](#data)).

## Package Structure

Organized by feature.

> [!TIP]
> A feature is a group of related code inside a directory, one special exception is the `common` directory which contains common code
> to be used across different features.

See also: https://docs.flutter.dev/app-architecture/case-study#package-structure

## `data`

Data sources (e.g., Network requests, File I/O operations, Databases), data classes, enums, and data types.

* **Returns raw data from APIs.**  
  The data sources typically return the raw data from the source without any modifications or transformations, ensuring they remain close to their original data format. Sometimes may perform minor transformations or response mappings when needed—for example, in `checkMinecraftJavaOwnership` for simplicity.
* **Response data classes may contain only relevant fields.**  
  While data sources should return raw data that closely matches the original format, they sometimes contain many fields. Too many unused fields from external APIs are often omitted or ignored without being fully parsed.
* **Data sources should be minimal, generic, and free of side effects or business logic.**  
Their responsibility is limited to low-level interactions with storage mechanisms (e.g., database, network, filesystem).  
For example, `readAccounts` in `FileAccountStorage` should simply return `null` if the file doesn’t exist, without creating it—even if that’s the intended behavior. Such logic should be handled in higher-level components like `AccountRepository`, which coordinates data sources and enforces application-specific rules. Refer to the [example](#example).
* **Defines only source models and types used by data sources.**  
  This layer includes data classes, enums, and types that represent how data is structured at the source level (e.g., API responses, local storage formats).  
  This layer does not include app models that are used by the [`logic`](#logic) and [`ui`](#ui) layers. For more info, refer to [Source models VS App models](#source-models-vs-app-models).
* **Defines the mappers that map source models to app models and vice versa.**

### Dependencies

* **Does not depend on the [`logic`](#logic) layer.**  
  The only exception is for mappers that convert **source models** to **app models**, which need to import the app model from the [`logic`](#logic) layer.

  **Note**: In Clean Architecture, the Data Layer depends on interfaces defined in the Domain Layer, while the Domain Layer remains independent of the Data Layer.
   However, this is not the case in this project, which follows Layered Architecture and **not Clean Architecture**.
* **Never depends on the [`ui`](#ui) layer.**

### Source models VS App models

* A **source model** (commonly called a DTO – Data Transfer Object or data model) defines how data is received from or sent to an external source. These models often include serialization/deserialization logic (e.g., JSON parsing).
* An **app model** (commonly called a domain model) defines application-specific structures used throughout the [`logic`](#logic) and [`ui`](#ui) layers. It is decoupled from data source formats. Changes in external APIs should only require updates to the corresponding source model—not the app model.

| Layer     | Uses App models? | Uses Source Models? | Why? |
|-----------|----------------|--------------|------|
| **Data**  | ❌ No           | ✅ Yes        | **Source models** represent raw data from data sources (e.g., API, DB, etc). |
| **Logic** | ✅ Yes          | ✅ Sometimes  | Work with **app models** for clean business logic to stay independent from the data sources. May map **source models** from the data sources to **app models**. |
| **UI**    | ✅ Yes          | ❌ No         | The UI is independent of the data sources and their **source/data models**. |

#### Naming

To clearly separate **source models** from **app models**, we follow a simple and consistent naming rule:

* A **source model** is named using the pattern `YX`, where:
  * `Y` is the source (e.g., `Api`, `File`, `Db`).
  * `X` is the model name (e.g., `Account`, `Instance`, `MinecraftVersion`).
  * Example: `FileAccount` for an account from a file.
* An **app model** is named using just `X`, without the source prefix.
  * Example: `Account`.

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
* **Should not include UI-specific logic**, such as user error messages, icons, navigation, state management (e.g., Flutter blocs/cubits), or formatting a `DateTime` into a readable `String` to the user.
* **Flutter blocs/cubits are part of the [`ui`](#ui), not this layer.**  
Which can be [confusing due to the name BLoC (Business Logic Components)](https://taej0127.medium.com/the-biggest-problem-of-bloc-is-the-name-bloc-1ba1522be5e2). These components typically [respond to input from the presentation layer (i.e., widgets) by emitting new states](https://bloclibrary.dev/architecture/#business-logic-layer). The blocs/cubits serve as [state holders](https://developer.android.com/topic/architecture#ui-layer) or controllers for widgets, [similar to how Android ViewModels are used](https://developer.android.com/topic/libraries/architecture/viewmodel).
* **Should avoid depending on Flutter-specific APIs (e.g., `BuildContext`) whenever possible.**  
Business logic should remain decoupled from the Flutter framework to improve testability and maintainability.  
In rare cases, using Flutter APIs is acceptable—primarily when integrating with platform-dependent plugins (e.g., [`shared_preferences`](https://pub.dev/packages/shared_preferences)). However, this should be avoided for plugins that perform UI-related tasks or navigation (e.g., [`url_launcher`](https://pub.dev/packages/url_launcher)) to keep the business logic layer free from UI dependencies.
* **Defines only **app models** and types used by this layer and the [`ui`](#ui) layer.**  
  For more info, read [Source models VS App models](#source-models-vs-app-models).
* **Contains Repositories.**  
  Repositories depend on one or more data sources and return data that meets the requirements. Data sources return source models, which repositories use and map to app models. The mappers that convert source models to app models are part of the [`data`](#data) layer but are only called within repositories.

  See also:

  * https://bloclibrary.dev/architecture/#repository
  * https://docs.flutter.dev/app-architecture/concepts#single-source-of-truth
  * https://docs.flutter.dev/app-architecture/guide#repositories

  **Note**: In Clean Architecture, the Domain Layer defines the repository interface and depends on it, while the Data Layer implements it so the Domain Layer remains independent of the Data Layer. Repository implementations are under the Data Layer. However, this project follows Layered Architecture and **not Clean Architecture**.

This layer is optional and is not always required, see also:

* https://docs.flutter.dev/app-architecture/guide#optional-domain-layer
* https://developer.android.com/topic/architecture#domain-layer

### Dependencies

* **Depends on the [`data`](#data) layer.**  
  Depends on data sources and source models from the [`data`](#data) layer.
  It should not heavily depend on the source models to minimize the changes needed when an external API introduces changes to its data structure.

  **Note**: In Clean Architecture, the Domain layer defines interfaces that the Data layer needs to implement so the Domain layer remains independent of the data layer.
   However, this is not the case in this project, which follows Layered Architecture and **not Clean Architecture**.
* **Never depends on the [`ui`](#ui) layer.**

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

Widgets, UI logic (e.g., localization, error messages), state management (e.g., Flutter blocs/cubits) and formatting a `DateTime` into a readable `String` to the user.

* **Should not depend directly on data sources or source models from the [`data`](#data) layer**, even when no state is required. Instead, it should depend on a business logic-specific class (e.g., `AccountRepository`). This layer usually doesn't need to depend on the `data` layer. UI code should not be affected when an external API makes changes to its data structure.
* **Prefers separating business logic from state management** to simplify testing and allow actions without triggering state changes when needed in the UI. Such logic belongs to the [`logic`](#logic) layer.

### Dependencies

* **Depends on the [`logic`](#logic) layer.**  
* **Does not depend on the [`data`](#data) layer.**  There is [one exception](#ui-layer-depends-on-the-failure-classes-of-the-data-source-of-the-data-layer) when handling errors coming from external APIs.

### Example

**Coming soon.**

## Violations

### [`ui`](#ui) layer depends on the failure classes of the data source of the [`data`](#data) layer

The `ui` layer may import some files from the `data` layer for the sealed classes that represent
the possible failures or errors coming from an external API, we will provide a full example
and explain why we think this approach is OK.

Assuming we have a data source called `MojangAuthApi`,
which could be a class that communicates with the Minecraft authentication APIs
and not the Api itself, it's more like `MojangAuthApiClient` for a consumer of the API.

```dart
class MojangAuthApi {
  MojangAuthApi(this.client);

  final HttpClient client;

  Future<Result<ApiAccount, MojangAuthFailure>> login(String username, String password) {
    try {
      final response = await client.post(
        Uri.https('api.minecraftservices.com', '/login'),
        data: {'username': username, 'password': password},
      );
    } on HttpClient catch(e) {
      if (e.response.statusCode == HttpStatus.tooManyRequests) {
        return Result.failure(TooManyRequestsFailure());
      }
      if (e.response.body['code'] == 'invalid_minecraft_credentials') {
        return Result.failure(InvalidCredentialsFailure());
      }
    }
    // ...
  }
}
```

The `MojangAuthFailure` could be something like:

```dart
@immutable
sealed class MojangAuthFailure {
  const MojangAuthFailure();
}

class NetworkFailure extends MojangAuthFailure {}
class TooManyRequestsFailure extends MojangAuthFailure {}
class InvalidCredentialsFailure extends MojangAuthFailure {}
class UnknownServerFailure extends MojangAuthFailure {
  final int code;
  const UnknownServerFailure(this.code);
}
class ParsingFailure extends MojangAuthFailure {}
class UnknownFailure extends MojangAuthFailure {}
```

Then in the repository:

```dart
class MojangAuthRepository {
  MojangAuthRepository({
    required this.mojangAuthApi
  });
  final MojangAuthApi mojangAuthApi;

  Future<Result<Account, MojangAuthFailure>> login(String username, String password) {
    final result = mojangAuthApi.login(username, password);
    return switch(result) {
      // 1. OK: Map ApiAccount to Account in case of success
      // 2. Violation: Return MojangAuthFailure from data layer without any mapping in case of failure
    };
  }
}
```

Although this is a violation of [separation-of-concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)
and the `MojangAuthRepository` should map the failure class that's specific to the data layer into a format that's
for the app to be used and handled in `ui` layer (to resolve the error messages), we do prefer it this way for two reasons:

1. We're already transforming the HTTP statuses and server codes that are low-level details and specific to the API in `MojangAuthApi`
   into a format that's suitable for the app.
2. The app functionality is already tightly coupled to this external API. If the API `api.minecraftservices.com` (`MojangAuthApi`)
   added new types of errors, removed or changed some, we're always affected by their decisions, and there is no use in
   mapping the sealed failure class.

However, the response `ApiAccount` should be mapped to `Account` since it's possible to decouple
their data structure from the app's data structure, and often it can be useful, especially
when they change their internal details, so we only need to update `ApiAccount`, which is only used by
`MojangAuthApi` and `MojangAuthRepository`, not the whole app code.

If the failure result class of `MojangAuthApi.login` exposes low-level details such as HTTP status or
server response body or other internal details, then yes, it should not be exposed to the `ui`, and
it should be mapped in `MojangAuthRepository`.

> [!TIP]
> If you think something can be improved or this design is invalid or an anti-pattern, we're open for discussion if you [open an issue](https://github.com/KraftLauncher/kraft-launcher/issues).

## Clean Architecture?

The **Layered architecture** is different from [Uncle Bob's **Clean Architecture**](https://en.wikipedia.org/wiki/Robert_C._Martin).

**Clean architecture** follows stricter rules:

* Has more abstractions, makes use of **interfaces/abstractions** in inner layers and implements them in outer layers.
* The domain layer defines interfaces that it uses to communicate with the data layer. The data layer implements the interfaces.
* Dependencies must point inward (towards the domain).
* Usually has more classes (use cases) where each use case has a single responsibility and must define only one public method/function (e.g. `UserFetcher.execute()`).
* The domain Layer is independent of any other layer.

While it's a matter of coding style and not related to any architecture, we avoid verbose suffixes like `DataSource` or `UseCase`. We prefer names like `VersionManifestFetcher` over `GetVersionManifestUseCase` and `OrderValidator` over `ValidateOrderUseCase`. Those naming conventions are commonly used in Flutter and Android apps that follow the Clean Architecture.

The Layered architecture is suggested by both Android and Flutter:

* https://developer.android.com/topic/architecture/recommendations#layered-architecture
* https://docs.flutter.dev/app-architecture/concepts#layered-architecture

## Resources

See also:

* [Bloc Architecture Guide](https://bloclibrary.dev/architecture/)
* [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture)
* [Android App Architecture Guide](https://developer.android.com/topic/architecture)
* [Project Code Style](./CODE_STYLE.md)
