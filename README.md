# Kraft Launcher

<p align="center">
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/stars/KraftLauncher/kraft-launcher" alt="Star on Github"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/actions"><img src="https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/EchoEllet/48575fd9d18dc33989ab0eb602af3b53/raw/7336b864ab67004197a6578a0ee8a8965b14ab71/kraft-launcher-coverage-badge.json" alt="Code Coverage Badge"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/actions/workflows/tests.yml"><img src="https://github.com/KraftLauncher/kraft-launcher/actions/workflows/tests.yml/badge.svg" alt="Tests"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/releases"><img src="https://img.shields.io/github/downloads/KraftLauncher/kraft-launcher/total" alt="GitHub Downloads (all assets, all releases)"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/repo-size/KraftLauncher/kraft-launcher" alt="GitHub repo size"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/languages/code-size/KraftLauncher/kraft-launcher" alt="GitHub code size in bytes"></a>
</p>

An open-source launcher for [Minecraft Java](https://www.minecraft.net/en-us/store/minecraft-java-bedrock-edition-pc) that provides instance isolation, seamless instance sharing with other players, and installing mods with ease.

> [!WARNING]
> This project is in its early stages and not yet ready for general use. For updates and progress, see [#1 Kraft Launcher progress](https://github.com/KraftLauncher/kraft-launcher/issues/1). **Breaking changes** are likely to be introduced at this point, which means your data will be lost once the launcher is released.

**Kraft Launcher is not affiliated
with [Mojang](https://mojang.com/), [Microsoft](https://www.microsoft.com/), or any of their
subsidiaries.**

## 📖 About

**Kraft Launcher** addresses the same issue as [Kraft Sync](https://github.com/FreshKernel/kraft-sync) for sharing and syncing instances. Due to limitations of the previous approach, a custom Minecraft launcher was developed to automate steps for a more user-friendly experience.

Our goal is to support standard features across most launchers while enabling players to share instances with others. This includes mods, resource packs, data packs, shaders, configs, key binds, and more, all kept in sync with automatic updates.

## 🖼️ Screenshots

<details>
<summary>Tap to show/hide screenshots</summary>

![Manage accounts screenshot](https://github.com/KraftLauncher/screenshots/blob/main/manage_minecraft_accounts.png?raw=true)

![Error loading accounts screenshot](https://github.com/KraftLauncher/screenshots/blob/main/error_loading_accounts.png?raw=true)

![Add Microsoft account dialog screenshot](https://github.com/KraftLauncher/screenshots/blob/main/adding_microsoft_account_dialog.png?raw=true)

![Settings general category screenshot](https://github.com/KraftLauncher/screenshots/blob/main/settings_general_category.png?raw=true)

![Settings about category screenshot](https://raw.githubusercontent.com/KraftLauncher/screenshots/refs/heads/main/settings_about_category.png)

![Logging in with Microsoft screenshot](https://github.com/KraftLauncher/screenshots/blob/main/logging_with_microsoft_dialog.png?raw=true)

![Accounts tab screenshot](https://github.com/KraftLauncher/screenshots/blob/main/accounts_tab.png?raw=true)

</details>

## ✨ Features

* 🔄 **Account Switching**: Seamlessly switch between multiple Microsoft accounts.
* 🔐 **Secure Authentication**: Microsoft account credentials are never exposed to the launcher — authentication is completed in the system browser. Account tokens are securely stored using the system’s secure storage (Windows Credential Manager, KDE Wallet, GNOME Keyring, or Apple Keychain).
* 📁 **Instance Isolation**: Each instance has its own data — separate mods, worlds, configs, and more.
* 🔗 **Instance Sharing & Syncing**: Effortlessly share complete instances with others, including mods, resource packs, configs, key binds, Java version, Minecraft version, mod loader versions, and more.
* 🔧 **Customizable Syncing**: Choose which mods, resource packs, and configurations to sync, or exclude specific ones for a more personalized experience.
* 🗂️ **Instance Groups**: Organize your instances using custom categories or labels.
* ☕ **Built-in Java Installer**: Automatically installs the right Java version per instance, cross-platform.
* 📦 **Modrinth + CurseForge Integration**: Install, update, and manage mods from both platforms.
* 🛠️ **Crash-Resistant**: View, copy, and share logs easily. Optionally upload to [mclo.gs](https://mclo.gs/) or similar services.
* 📥 **Import from Other Launchers**: Bring your instances and files from MultiMC or other launchers.
* 📰 **News Feed**: Get the latest Minecraft news right in the launcher.
* 🎨 **Modern UI**: Clean interface built with [Material Design 3](https://m3.material.io/), supporting dark/light themes, dynamic colors, and custom accents.
* ⚡ **Quick Play**: Automatically join a Minecraft server, world, or realm on launch.

> [!IMPORTANT]
> Currently, the project doesn't implement most of these features yet, they were added early in `README` as they are planned in [#1 Kraft Launcher progress](https://github.com/KraftLauncher/kraft-launcher/issues/1), once they are available, this note will be removed.

## 🛠️ Build from Source

<details>
<summary>Tap to show/hide build instructions</summary>

1. Ensure [Flutter](https://docs.flutter.dev/get-started/install) is installed.
2. On Linux, install the following dependencies:

    * [Flutter dependencies](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools):
        - **Debian or Ubuntu**: `sudo apt install -y curl git unzip xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev`
        - **Fedora**: `sudo dnf install -y curl git unzip xz zip mesa-libGLU clang cmake ninja-build pkgconf-pkg-config gtk3-devel xz-devel libstdc++-devel`
    * App dependencies:
        - **Debian or Ubuntu**: `sudo apt install -y libsecret-1-dev libsecret-1-0`
        - **Fedora**: `sudo dnf install -y libsecret-devel libsecret`

3. Run the following:

    ```bash
    git clone --depth 1 https://github.com/KraftLauncher/kraft-launcher
    cd kraft-launcher
    # Fetch dependencies for the whole workspace
    flutter pub get

    # Build the app package
    cd kraft_launcher
    flutter build <platform>
    ```

    Replace `<platform>` with `linux`, `macos` or `windows`.

</details>

## 🔄 Forks & Redistribution

If you plan to fork or redistribute this project, please follow these guidelines:

* Do not crack, pirate, or distribute builds that bypass Minecraft: Java Edition ownership checks. This is illegal and not supported. Offline mode is available, but users must own the game on at least one Microsoft account.
* Replace all API keys with your own or use empty strings (`''`). This includes the [Microsoft Login Client ID and CurseForge API key][project_constants], located in `ProjectInfoConstants`.
* Update all branding, including the launcher name, app IDs and assets:
    * All static fields in [`ProjectInfoConstants`][project_constants] should be updated, including the app name.
    * Update all files inside [assets/branding][assets_branding]. Also run `dart run flutter_launcher_icons:generate` to replace them in platform runners.
    * The package name in [`pubspec.yaml`][app_pubspec.yaml] and also the app id in the platform runners [`linux`][platform_linux], [`macos`][platform_macos] and [`windows`][platform_windows]. Also refer to [Platform Runner Modifications](./docs/PLATFORM_RUNNER_MODIFICATIONS.md).
* Clearly state that your fork is not affiliated with or endorsed by **Kraft Launcher**.

This launcher interacts with APIs and services that requires to review and accept the following terms and conditions:

- Microsoft
    - [Microsoft Identity Platform Terms of Use](https://learn.microsoft.com/en-us/legal/microsoft-identity-platform/terms-of-use)
    - [Microsoft APIs Terms of Use](https://learn.microsoft.com/legal/microsoft-apis/terms-of-use)
    - [Microsoft Services Agreement](https://www.microsoft.com/servicesagreement)
    - [Microsoft Trademark and Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks)
- Minecraft:
    - [Minecraft Usage Guidelines](https://www.minecraft.net/usage-guidelines)
    - [Minecraft EULA](https://www.minecraft.net/eula)
- Course Forge: 
    - [CurseForge 3rd Party API Terms and Conditions](https://support.curseforge.com/en/support/solutions/articles/9000207405-curse-forge-3rd-party-api-terms-and-conditions)
    - [CurseForge for Studios Terms of Use](https://docs.curseforge.com/docs/legal/terms-of-use/)

## 🌱 Contributing

For contribution guidelines, please refer to the [Contributing Guide](./CONTRIBUTING.md).

## ⚠️ Disclaimer

> [!WARNING]
> **Kraft Launcher is NOT AN OFFICIAL MINECRAFT PRODUCT.  
It is NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.**

## 📜 Acknowledgments

We are incredibly grateful to many individuals and organizations who have played a role in the project. This includes the welcoming community, dedicated volunteers, talented developers and contributors, the creators of the open-source tools and the information we rely on.

- [Flutter](https://flutter.dev/)
- [Bloc](https://bloclibrary.dev/)
- The app icon was created with the assistance of a generative design tool.
- The following open-source launchers were referenced for implementing certain features:
    - [PrismLauncher](https://github.com/PrismLauncher/PrismLauncher)
    - [ATLauncher](https://github.com/ATLauncher/ATLauncher/)
    - [Pencil](https://github.com/Dreta/Pencil)
- [mojang-meta-urls](https://gist.github.com/skyrising/95a8e6a7287634e097ecafa2f21c240f) gist.
- The following Minecraft wikis:
    - [Mojang API](https://minecraft.wiki/w/Mojang_API)
    - [Microsoft authentication](https://minecraft.wiki/w/Microsoft_authentication)
    - [Version_manifest.json](https://minecraft.wiki/w/Version_manifest.json)
    - [Version.json](https://minecraft.wiki/w/Version.json)
    - [Client.jar](https://minecraft.wiki/w/Client.jar)
    - [Client.json](https://minecraft.wiki/w/Client.json)
    - [Launcher_profiles.json](https://minecraft.wiki/w/Launcher_profiles.json)
    - [Options.txt](https://minecraft.wiki/w/Options.txt)
    - [Servers.dat_format](https://minecraft.wiki/w/Servers.dat_format)
    - [Quick Play](https://minecraft.wiki/w/Quick_Play)

<!-- Link references for easier maintenance -->
[project_constants]: ./kraft_launcher/lib/common/constants/project_info_constants.dart
[assets_branding]: ./kraft_launcher/assets/branding
[app_pubspec.yaml]: ./kraft_launcher/pubspec.yaml
[platform_linux]: ./kraft_launcher/linux
[platform_macos]: ./kraft_launcher/macos
[platform_windows]: ./kraft_launcher/windows
