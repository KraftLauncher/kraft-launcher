# 🌱 Contributing

Thanks for your interest on contributing to **Kraft Launcher**!

> [!NOTE]  
> We highly encourage [creating issues on GitHub](https://github.com/KraftLauncher/kraft-launcher/issues/new) before working on them—especially for medium to large changes.

## 📜 Code of Conduct

Please review our [Code of Conduct](./CODE_OF_CONDUCT.md) to understand the expected standards of behavior when participating in this project.

## 🎨 Code Style

Also, see [Project Architecture](./docs/ARCHITECTURE.md).

- [Effective Dart](https://dart.dev/effective-dart).
- [Writing Effective Tests](https://github.com/flutter/flutter/blob/master/docs/contributing/testing/Writing-Effective-Tests.md).
- [Style guide for Flutter repo](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md).
- [Project Code Style](docs/CODE_STYLE.md) (**Not finished yet**)
- [Linux kernel coding style](https://www.kernel.org/doc/html/v4.10/process/coding-style.html) – while not directly applicable, it offers valuable insights and inspiration for maintaining consistent and readable code.

## 📋 Prerequisites

- Linux, macOS, or Windows.
- [Flutter](https://docs.flutter.dev/get-started/install) installed and added to your `PATH`.
- [git](https://git-scm.com/) for version control.
- [Commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification) set up for your GitHub account (optional but recommended).
- [Minecraft account](https://www.minecraft.net/store/minecraft-deluxe-collection-pc) to launch the game and test Microsoft refresh and login flows, skins and capes management and more (optional).

## 🍴 Forking & cloning the repository

- Fork the [GitHub repo](https://github.com/KraftLauncher/kraft-launcher) to your account. If you already have a fork, make sure it’s up to date. 
* Clone your fork:

    ```bash
    git clone git@github.com:<your_name_here>/kraft-launcher.git
    cd kraft-launcher
    ```

* Add the upstream repo:

    ```bash
    git remote add upstream git@github.com:KraftLauncher/kraft-launcher.git
    ```

    This allows you to fetch updates from the main repository.

## 🧪 Testing

To run tests:

* **Unit tests**: 

    ```bash
    flutter test
    ```

* **End-to-end (E2E) tests**: 

    ```bash
    flutter test integration_test
    ```

> [!NOTE]
> In this project, the UI is generally not as heavily tested as the business logic.

> [!TIP]
>  Useful testing resources:
> - [Flutter unit tests](https://docs.flutter.dev/cookbook/testing/unit/introduction).
> - [Mock dependencies using Mockito](https://docs.flutter.dev/cookbook/testing/unit/mocking).
> - [Flutter widget tests docs](https://docs.flutter.dev/cookbook/testing/widget/introduction)
> - [Flutter integration tests docs](https://docs.flutter.dev/testing/integration-tests).

## ⚙️ Development Notes

- Run `flutter gen-l10n` when updating localization `.arb` files in [l10n](./l10n/) directory. Also update `AppLanguage` enum when adding new localizations, a unit test will fails if not in sync.
- Run `dart run build_runner build --delete-conflicting-outputs` or [`fluttergen`](https://pub.dev/packages/flutter_gen#usage) when adding and deleting files inside the `assets` directory.
- Run `dart ./scripts/generate_pubspec_dart_code.dart` when updating `pubspec.yaml`.
