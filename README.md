# Kraft Launcher

<p align="center">
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/stars/KraftLauncher/kraft-launcher" alt="Star on Github"></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/actions"><img src="https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/EchoEllet/48575fd9d18dc33989ab0eb602af3b53/raw/d3f41f773e351ea4fc35c411d2c84ace1f49ebc4/kraft-launcher-coverage-badge.json" alt="Code Coverage Badge"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/actions/workflows/tests.yml"><img src="https://github.com/KraftLauncher/kraft-launcher/actions/workflows/tests.yml/badge.svg" alt="Tests"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher/releases"><img src="https://img.shields.io/github/downloads/KraftLauncher/kraft-launcher/total" alt="GitHub Downloads (all assets, all releases)"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/repo-size/KraftLauncher/kraft-launcher" alt="GitHub repo size"></a>
<a href="https://github.com/KraftLauncher/kraft-launcher"><img src="https://img.shields.io/github/languages/code-size/KraftLauncher/kraft-launcher" alt="GitHub code size in bytes"></a>
</p>

An unofficial, open-source launcher for [Minecraft Java](https://www.minecraft.net/en-us/store/minecraft-java-bedrock-edition-pc) that provides profile isolation, seamless profile sharing with other players, and installing mods with ease.

> [!WARNING]
> This project is in its early stages and not yet ready for general use. For updates and progress, see [#1 Kraft Launcher progress](https://github.com/KraftLauncher/kraft-launcher/issues/1). **Breaking changes** are likely to be introduced at this point, which means your data will be lost once the launcher is released.

**Kraft Launcher is not affiliated
with [Mojang](https://mojang.com/), [Microsoft](https://www.microsoft.com/), or any of their
subsidiaries.**

## 📖 About

**Kraft Launcher** addresses the same issue as [Kraft Sync](https://github.com/FreshKernel/kraft-sync) for sharing and syncing profiles (AKA instances). Due to limitations of the previous approach, a custom Minecraft launcher was developed to automate steps for a more user-friendly experience.

Our goal is to support standard features across most launchers while enabling players to share profiles with others. This includes mods, resource packs, data packs, shaders, configs, key binds, and more, all kept in sync with automatic updates.

## 🖼️ Screenshots

<details>
<summary>Tap to show/hide screenshots</summary>

![Manage accounts screenshot](https://github.com/user-attachments/assets/c15745c3-999f-4407-b9b5-67b02654b430)

![Error loading accounts screenshot](https://github.com/user-attachments/assets/364e76a3-97e7-4aae-8fc2-371ddd5f537f)

![Add Microsoft account dialog screenshot](https://github.com/user-attachments/assets/a37f40c1-6186-4cfc-9561-96ce5b8e6464)

![Settings general category screenshot](https://github.com/user-attachments/assets/a17740c7-8dc2-4ff7-9536-1ed2049e3b75)

![Settings about category screenshot](https://github.com/user-attachments/assets/eb7bce4a-e9e4-4533-966c-b3a313c7f03e)

![Logging in with Microsoft screenshot](https://github.com/user-attachments/assets/da9e08f9-63bb-40af-a087-224463ca3cc0)

![Accounts tab screenshot](https://github.com/user-attachments/assets/4553eee0-ac39-481c-bb00-96cc74ae901c)

</details>

## ✨ Features

* 🔄 **Account Switching**: Seamlessly switch between multiple Microsoft accounts.
* 📁 **Profile Isolation**: Each profile has its own data — separate mods, worlds, configs, and more.
* 🔗 **Profile Sharing & Syncing**: Effortlessly share complete profiles with others, including mods, resource packs, configs, key binds, Java version, Minecraft version, mod loader versions, and more.
* 🔧 **Customizable Syncing**: Choose which mods, resource packs, and configurations to sync, or exclude specific ones for a more personalized experience.
* 🗂️ **Profile Groups**: Organize your profiles using custom categories or labels.
* ☕ **Built-in Java Installer**: Automatically installs the right Java version per profile, cross-platform.
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

Ensure [Flutter](https://docs.flutter.dev/get-started/install) is installed, and then run:

```bash
git clone --depth 1 https://github.com/KraftLauncher/kraft-launcher
cd kraft-launcher
flutter pub get
flutter build <platform>
```

Replace `<platform>` with `linux`, `macos` or `windows`.

</details>

## 🔄 Forks & Redistribution

If you plan to fork or redistribute this project, please follow these guidelines:

* Do not crack, pirate, or distribute builds that bypass Minecraft: Java Edition ownership checks. This is illegal and not supported. Offline mode is available, but users must own the game on at least one Microsoft account.
* Update all branding, including the launcher name, app IDs and assets:
    * All static fields in [`ProjectInfoConstants`](./lib/common/constants/project_info_constants.dart) should be updated, including the app name.
    * Update all files inside [assets/branding](./assets/branding). Also run `dart run flutter_launcher_icons:generate` to replace them in platform runners.
    * The package name in `pubspec.yaml` and also the app id in the platform runners `linux`, `macos` and `windows`. Also refer to [Platform Runner Modifications](./docs/PLATFORM_RUNNER_MODIFICATIONS.md).
* Clearly state that your fork is not affiliated with or endorsed by **Kraft Launcher**.
* Replace all API keys with your own or use empty strings (`''`). This includes the [Microsoft Login Client ID](./lib/common/constants/microsoft_constants.dart) and the CurseForge API key.

This launcher depends on APIs and services that requires to accept the following terms and conditions:

- [Microsoft Identity Platform Terms of Use](https://docs.microsoft.com/en-us/legal/microsoft-identity-platform/terms-of-use)
- [Minecraft EULA and Usage Guidelines](https://www.minecraft.net/en-us/usage-guidelines)
- [CurseForge 3rd Party API Terms and Conditions](https://support.curseforge.com/en/support/solutions/articles/9000207405-curse-forge-3rd-party-api-terms-and-conditions)

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
