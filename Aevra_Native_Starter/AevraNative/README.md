# Aevra Native

A real SwiftUI iPhone app foundation for Aevra.

## Included

- Native SwiftUI glass interface
- Home, Flow, Studio, Live, and Profile tabs
- Editable routines and tasks
- Persistent local storage
- Focus timer
- Local notifications
- Theme controls
- Unit tests
- XcodeGen project spec
- GitHub Actions unsigned IPA build

## Build an unsigned IPA from Windows

1. Create a GitHub repository.
2. Upload all files from this folder.
3. Open **Actions** in GitHub.
4. Run **Build Aevra IPA**.
5. Download the `Aevra-Unsigned-IPA` artifact.
6. Extract the artifact and install the IPA with Sideloadly.

The GitHub workflow uses a macOS runner because Apple apps must be compiled with Xcode.

## Build locally on a Mac

```bash
brew install xcodegen
xcodegen generate
open Aevra.xcodeproj
```

Choose your development team in Xcode, connect an iPhone, and press Run.

## Current scope

This is the first native milestone. Widgets and Live Activities are intentionally left for the next milestone so the base app can compile cleanly first.
