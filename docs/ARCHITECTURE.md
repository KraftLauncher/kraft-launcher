# Architecture

This project splits code into features (e.g., `account`), where [each feature contains 3 layers](https://docs.flutter.dev/app-architecture/concepts#layered-architecture):

* `data`: Network requests, I/O operations, data sources, data classes, enums, and data types.
    * Usually returns the raw data from APIs but sometimes may make minor transformations or response mappings, such as in `checkMinecraftJavaOwnership` for simplicity reasons.
    * The response data classes contain only the relevant or needed fields. Other fields are not parsed and are silently ignored.
* `logic`: Business logic and state management, usually depends on the data sources from the `data` layer.
    * Should not contain any I/O operations or network requests, as that makes it harder to mock dependencies in unit testing. Those should go in the data layer instead.
    * Prefers separating business logic from state management logic to make writing tests easier and to allow performing actions without changing state when needed in the UI. For example, both `MinecraftAccountManager` and `AccountCubit` are in the same `logic` directory, `AccountCubit` depends on `MinecraftAccountManager` but `MinecraftAccountManager` does not depends on `AccountCubit`.
    * Should not contain UI-specific logic like error messages or icons.
* `ui`: Widgets and UI logic (e.g., localization, error messages).
    * Should not depend on the `data` layer directly, even if it doesn’t need any state. Instead, it should depend on a business logic-specific class (e.g., `MinecraftAccountManager`).

> [!TIP]
> A feature is a group of related code inside a directory, one special exception is the `common` directory which contains common code
> to be used across different features.

This architecture is different from clean architecture. Clean architecture follows more strict rules, has more abstractions and is more generic.
