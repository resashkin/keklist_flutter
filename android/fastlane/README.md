fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build_and_upload_to_internal

```sh
[bundle exec] fastlane android build_and_upload_to_internal
```

Build AAB and upload to Play Store internal testing track

### android build_aab_flutter

```sh
[bundle exec] fastlane android build_aab_flutter
```

Build AAB only (for testing)

### android distribute_firebase

```sh
[bundle exec] fastlane android distribute_firebase
```

Build APK and distribute to Firebase App Distribution

### android distribute_firebase_with_notes

```sh
[bundle exec] fastlane android distribute_firebase_with_notes
```

Build APK and distribute to Firebase with custom release notes

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
