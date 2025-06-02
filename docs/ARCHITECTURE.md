# Architecture

This project splits code into features (e.g., `account`), where [each feature contains 3 layers](https://docs.flutter.dev/app-architecture/concepts#layered-architecture):

## `data`

Network requests, I/O operations, data sources, data classes, enums, and data types.

* **Usually returns raw data from APIs**, but may perform minor transformations or response mappings when needed—for example, in `checkMinecraftJavaOwnership` for simplicity.
* **Response data classes include only relevant fields**. Unused fields from APIs are not parsed and are silently ignored.
* **Data sources should be minimal, generic, and free of side effects or business logic.**  
Their responsibility is limited to low-level interactions with storage mechanisms (e.g., database, network, filesystem).  
For example, `readAccounts` in `FileAccountStorage` should simply return `null` if the file doesn’t exist, without creating it—even if that’s the intended behavior. Such logic should be handled in higher-level components like `AccountRepository`, which coordinates data sources and enforces application-specific rules.

## `logic`

Business logic and state management, usually depends on the data sources from the `data` layer.

* **Should not contain any I/O operations or network requests**, as this complicates mocking dependencies in unit tests. Such operations belong exclusively in the data layer.
* **Prefers separating business logic from state management** to simplify testing and allow actions without triggering state changes when needed in the UI.
* **Should not include UI-specific logic**, such as error messages or icons.
* **Should avoid depending on Flutter-specific APIs (e.g., `BuildContext`) whenever possible.**  
Business logic should remain decoupled from the Flutter framework to improve testability and maintainability.  
In rare cases, using Flutter APIs is acceptable—primarily when integrating with platform-dependent plugins (e.g., [`shared_preferences`](https://pub.dev/packages/shared_preferences)). However, this should be avoided for plugins that perform UI-related tasks or navigation (e.g., [`url_launcher`](https://pub.dev/packages/url_launcher)) to keep the business logic layer free from UI dependencies.

## `ui`

Widgets and UI logic (e.g., localization, error messages).

* **Should not depend directly on the `data` layer**, even when no state is required. Instead, it should depend on a business logic-specific class (e.g., `AccountRepository`).

> [!TIP]
> A feature is a group of related code inside a directory, one special exception is the `common` directory which contains common code
> to be used across different features.

This architecture is different from Clean Architecture. Clean Architecture follows stricter rules, has more abstractions, and is more generic. We also use fewer classes and avoid verbose suffixes like `DataSource` or `UseCase`.
