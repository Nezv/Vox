# Vox

A cross-platform (Windows + Android) TTS reader app with a minimalist UI.

See `project.md` for the feature roadmap and `status.md` for progress.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22 or newer (Dart 3.4+).
- Android toolchain (Android Studio + SDK) to build / run on Android.
- Visual Studio 2022 with the "Desktop development with C++" workload to build / run on Windows.

Verify the install:

```bash
flutter --version
flutter doctor
```

## One-time setup

The repo is committed without generated platform directories. After cloning, run:

```bash
flutter create --project-name vox --org com.vox --platforms=windows,android .
flutter pub get
```

`flutter create` fills in the missing `android/` and `windows/` runners without touching `lib/`, `test/`, or the docs.

## Run

```bash
# Windows
flutter run -d windows

# Android (emulator or connected device)
flutter run -d android
```

## Test

```bash
flutter analyze
flutter test
```
