# ninja_material

Shared Flutter library powering all ninja apps. Provides Material You theming, localization, navigation scaffolding, and CI/CD workflows.


## Features

- **`runNinjaApp()`** — single entry point for all apps, wires up theming, localization, and providers
- **`FirstPageConfig`** — configures the navigation shell (destinations, pages, bottom bar)
- **Material You theming** — dynamic color with `dynamic_color`, light/dark mode
- **Localization** — base strings in 6 languages (en, de, es, fr, it, ja), extendable per app
- **Reusable CI/CD workflows** — shared GitHub Actions for version bumping, APK builds, and web deploys




## Build

```bash
# Prerequisites: Flutter SDK 3.41.5+
flutter pub get
flutter build web --release
```

## Usage

Add to `pubspec.yaml`, pinned to a release tag:

```yaml
dependencies:
  ninja_material:
    git:
      url: https://github.com/Giuig/ninja_material.git
      ref: v1.3.0
```

Bootstrap your app:

```dart
import 'package:ninja_material/bootstrap.dart';

void main() {
  runNinjaApp(
    defaultSeedColor: Colors.teal,
    specificLocalizationDelegate: AppLocalizations.delegate,
    appFirstPageConfig: myFirstPageConfig,
  );
}
```


## Reusable workflows

Reference from any app repo:

```yaml
# .github/workflows/build.yml
jobs:
  build:
    uses: Giuig/ninja_material/.github/workflows/build-app.yml@main
    with:
      app-name: myapp
      package-id: com.myapp
      version: ${{ github.ref_name }}
    secrets: inherit
```

Available workflows:
- `build-app.yml` — builds universal + split APKs and creates a GitHub release
- `version-bump.yml` — auto-tags and triggers builds on `pubspec.yaml` changes
- `web-deploy.yml` — deploys to GitHub Pages


## Part of the ninja apps family

| App | Description |
|---|---|
| [tvninja](https://github.com/Giuig/tvninja) | IPTV / M3U8 player |
| [auraninja](https://github.com/Giuig/auraninja) | Ambient sound mixer and focus app |
| [decisioninja](https://github.com/Giuig/decisioninja) | Decision maker with dice, pointer, and binary choices |

## License

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE)

This project is licensed under the [GNU General Public License v3.0](./LICENSE).
