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

## Library Storage

- Use the `Import books` action in the library screen to select one or more `.md` files.
- Vox copies imported files into a persistent local library folder.
- On Windows debug/dev runs, the default library location is `Documents/VoxLibrary`.
- Imported books remain available across app restarts.

## Debug Play Crashes (TTS)

Use startup flags to switch TTS backends without editing code:

- `VOX_TTS=auto` (default) uses `mock` on Windows debug, `real` otherwise.
- `VOX_TTS=real` uses `FlutterTtsEngine` (native plugin path).
- `VOX_TTS=mock` uses `SimulatedTtsEngine` (no native TTS dependency).
- `VOX_TTS=noop` uses `NoopTtsEngine` (no speech, no boundaries).
- `VOX_TTS_TRACE=true` logs all TTS commands/events.

PowerShell examples:

```powershell
# 1) Reproduce without native plugin
flutter run -d windows --dart-define=VOX_TTS=mock --dart-define=VOX_TTS_TRACE=true

# 2) Compare with native plugin enabled
flutter run -d windows --dart-define=VOX_TTS=real --dart-define=VOX_TTS_TRACE=true
```

How to read results:

- If `mock` mode is stable but `real` mode crashes, the issue is likely in native/plugin TTS.
- If both modes crash, inspect playback/state/UI flow first.
- In trace logs, look for `speak` calls without follow-up events (`started`, `boundary`, `completed`) to spot stuck playback.

## Test

```bash
flutter analyze
flutter test
```
