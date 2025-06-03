# App Build sizes

Latest build size (uncompressed and compressed) for each desktop platform.

| Platform | Uncompressed Size | Compressed Size | Compression Format |
|----------|-------------------|-----------------|---------------------|
| Linux    | [54 MB](#linux-detailed-size-analysis)             | 20.4 MB           | .tar.gz             |
| macOS    | [60 MB](#macos-detailed-size-analysis)               | 25.9 MB             | .zip                |
| Windows  | [31 MB](#windows-detailed-size-analysis)               | 13.9 MB             | .zip                |

> [!NOTE]
> Updated after running `flutter build <platform> --analyze-size` and compressing the output folder.

Last run on `2025-06-03`, commit [`30bc1e6d306be574a6f9182051ac730d814c6874`](https://github.com/KraftLauncher/kraft-launcher/commit/30bc1e6d306be574a6f9182051ac730d814c6874).

## Linux Detailed Size Analysis

```console
bundle                                                          54 MB
└── bundle/
    ├── kraft_launcher                                          20 KB
    ├── data/
    │   ├── icudtl.dat                                         761 KB
    │   └── flutter_assets                                       4 MB
    └── lib/
        ├── libflutter_linux_gtk.so                             41 MB
        ├── libdynamic_color_plugin.so                          18 KB
        ├── libfile_selector_linux_plugin.so                    37 KB
        ├── libflutter_secure_storage_linux_plugin.so          163 KB
        ├── liburl_launcher_linux_plugin.so                     26 KB
        └── libapp.so (Dart AOT)                                 8 MB
            └── Dart AOT symbols accounted decompressed size     8 MB
                ├── package:flutter                              4 MB
                ├── package:lottie                             387 KB
                ├── dart:core                                  319 KB
                ├── package:kraft_launcher                     265 KB
                ├── dart:ui                                    258 KB
                ├── package:flutter_localizations              216 KB
                ├── dart:io                                    190 KB
                ├── dart:typed_data                            189 KB
                ├── dart:async                                 133 KB
                ├── package:dbus                               122 KB
                ├── package:intl                               104 KB
                ├── package:material_color_utilities            98 KB
                ├── dart:convert                                95 KB
                ├── package:flex_color_picker                   81 KB
                ├── dart:collection                             76 KB
                ├── package:dio                                 70 KB
                ├── package:go_router                           70 KB
                ├── package:vector_math/
                │   └── vector_math_64.dart                     45 KB
                ├── package:source_span                         45 KB
                └── package:flutter_cache_manager               40 KB
```

## macOS Detailed Size Analysis

```console
Kraft Launcher.app                                                       60 MB
└── Kraft Launcher.app/
    └── Contents/
        ├── _CodeSignature                                               13 KB
        ├── MacOS                                                         1 MB
        ├── Resources                                                     1 MB
        ├── Frameworks                                                   57 MB
        ├── Dart AOT symbols accounted decompressed size                  8 MB
        │   ├── package:flutter                                           4 MB
        │   ├── package:lottie                                          373 KB
        │   ├── dart:core                                               318 KB
        │   ├── package:kraft_launcher                                  261 KB
        │   ├── dart:ui                                                 241 KB
        │   ├── package:flutter_localizations                           223 KB
        │   ├── dart:typed_data                                         195 KB
        │   ├── dart:io                                                 188 KB
        │   ├── dart:async                                              156 KB
        │   ├── package:dbus                                            119 KB
        │   ├── package:intl                                            102 KB
        │   ├── dart:convert                                             96 KB
        │   ├── package:material_color_utilities                         94 KB
        │   ├── dart:collection                                          82 KB
        │   ├── package:flex_color_picker                                78 KB
        │   ├── package:go_router                                        70 KB
        │   ├── package:dio                                              69 KB
        │   ├── package:sqflite_common                                   48 KB
        │   ├── package:source_span                                      45 KB
        │   └── package:vector_math/
        │       └── vector_math_64.dart                                  42 KB
        └── Info.plist                                                    2 KB
```

## Windows Detailed Size Analysis

```console
Release [31 MB]
└── Release/
    ├── data/
    │   ├── app.so (Dart AOT) [8 MB]
    │   ├── Dart AOT symbols accounted decompressed size [8 MB]
    │   │   ├── package:flutter [4 MB]
    │   │   ├── package:lottie [387 KB]
    │   │   ├── dart:core [340 KB]
    │   │   ├── package:kraft_launcher [264 KB]
    │   │   ├── dart:ui [261 KB]
    │   │   ├── package:flutter_localizations [216 KB]
    │   │   ├── dart:io [195 KB]
    │   │   ├── dart:typed_data [190 KB]
    │   │   ├── dart:async [133 KB]
    │   │   ├── package:dbus [127 KB]
    │   │   ├── package:intl [104 KB]
    │   │   ├── package:material_color_utilities [98 KB]
    │   │   ├── dart:convert [89 KB]
    │   │   ├── package:flex_color_picker [81 KB]
    │   │   ├── dart:collection [76 KB]
    │   │   ├── package:dio [70 KB]
    │   │   ├── package:go_router [70 KB]
    │   │   ├── package:vector_math/
    │   │   │   └── vector_math_64.dart [46 KB]
    │   │   ├── package:source_span [45 KB]
    │   │   └── package:flutter_cache_manager [40 KB]
    │   ├── flutter_assets [4 MB]
    │   └── icudtl.dat [761 KB]
    ├── dynamic_color_plugin.dll [82 KB]
    ├── file_selector_windows_plugin.dll [113 KB]
    ├── flutter_secure_storage_windows_plugin.dll [161 KB]
    ├── flutter_windows.dll [18 MB]
    ├── kraft_launcher.exe [60 KB]
    └── url_launcher_windows_plugin.dll [99 KB]
```
