# Code Style

> [!IMPORTANT]
> Currently, this document is a WIP, we have created it to collect our 
ideas but at some point it will be fully rewritten to adhere to our standards.

**This document has been written very quickly, just to document the 
current conventions but will we rewritten fully in the future.**

## Exceptions

### Always import `*_exceptions.dart` files with a prefix

<!-- TODO: We might want to apply this for all public sealed classes? See also https://docs.flutter.dev/app-architecture/design-patterns/result#putting-it-all-together
 -->

#### ✅ Preferred

```dart
import 'minecraft_exceptions.dart' as minecraft_exceptions;
```

#### 🚫 Avoid

```dart
import 'minecraft_exceptions.dart';
```

#### Reason

To avoid name collisions and make it clear where the exception originates.

### Avoid including the sealed class name in subclasses

#### ✅ Preferred

```dart
sealed class MinecraftException {}

final class UserNotFoundException extends MinecraftException {}
```

#### 🚫 Avoid

```dart
sealed class MinecraftException {}

final class MinecraftUserNotFoundException extends MinecraftException {}
```

#### Example Usage

```dart
import 'minecraft_exceptions.dart' as minecraft_exceptions;

minecraft_exceptions.UserNotFoundException();
```

#### Reason

Including the sealed class name in subclasses can become very verbose, making the code harder to maintain, read, and refactor.

## Prefer [`@docImport`](https://dart.dev/tools/doc-comments/references#doc-imports) over `import` when referencing APIs in Dart doc comment

#### ✅ Preferred

```dart
/// @docImport 'minecraft_account_refresher.dart';
library;
```

#### 🚫 Avoid

```dart
import 'minecraft_account_refresher.dart';
```

#### Acceptable

Prefer `import` over `@docImport` when using prefixes since `@docImport` doesn't support `as`:

```dart
import 'microsoft_auth_api_exceptions.dart'
    as microsoft_auth_api_exceptions;
```
