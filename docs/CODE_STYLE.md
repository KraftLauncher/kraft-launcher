# Code Style

> [!IMPORTANT]
> Currently, this document is a WIP, we have created it to collect our 
ideas but at some point it will be fully rewritten to adhere to our standards.

**This document has been written very quickly, just to document the 
current conventions but will we rewritten fully in the future.**

## Naming Conventions

### Exceptions

```
<Scope><FailureType>Exception
```

When defining exceptions, follow a naming pattern that reflects both the **scope** and the **type of failure**.

For example, if you have a class `MinecraftAccountApi` with a corresponding sealed exception class `MinecraftAccountApiException`, and several specific subclasses, it's generally preferred to **prefix those subclasses with part of the sealed class name**—but not necessarily the full name—since the full name can become overly long and verbose.

#### ✅ Preferred

```dart
MicrosoftAuthUnknownException
```

#### 🚫 Avoid

```dart
MicrosoftAuthApiUnknownException
```

In this case, `MicrosoftAuthUnknownException` is clearer and more concise, while still indicating its relationship to the sealed class `MicrosoftAuthApiException`.
