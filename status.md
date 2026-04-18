# Vox dev environment — status tracker

## 2026-04-17 — PR 1: Flutter scaffold + theme system

### Done
- Pinned Flutter/Dart SDK constraints in `pubspec.yaml` (Flutter ≥ 3.22, Dart ≥ 3.4), no third-party state-management deps.
- `analysis_options.yaml` with `flutter_lints`.
- `.gitignore` covering Dart/Flutter build artifacts and platform folders.
- `lib/core/constants.dart` — `kAppTitle = 'Vox'` as the single source of truth for the title.
- `lib/core/theme/app_theme.dart` — Material 3 light, dark, and sepia (`#F4ECD8` / `#3B2F2F`) themes plus `AppThemeMode` enum and `themeFor(mode)` selector.
- `lib/core/theme/theme_controller.dart` — `ChangeNotifier` holding the current mode (no persistence yet).
- `lib/app.dart` — `VoxApp` + `HomeScaffold` with `AppBar` showing "Vox" and a `SegmentedButton` cycling through the three themes.
- `lib/main.dart` — entry point.
- Stub feature dirs: `lib/features/{library,reader,tts,settings}/.gitkeep`.
- `test/widget_test.dart` — asserts "Vox" appears in the `AppBar` and that the theme cycler doesn't crash.

### Not yet done (blocking next verification step)
- Flutter SDK is **not installed** on this machine, so `flutter create .` hasn't been run. That means:
  - `android/` and `windows/` platform dirs are not generated yet.
  - `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build` were not executed.
- Once Flutter is installed, run `flutter create --project-name vox --org dev.vox --platforms=windows,android .` from the repo root. It will fill in the missing platform dirs without overwriting existing `lib/` or docs. Then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build {apk,windows} --debug`.

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Library view and book view with switching.
- Two-page read layout that fills most of the screen, sweeping two pages at a time.
- Import / delete / rename / organize `.md` books.
- Word-by-word TTS highlighting.
- Time + progress feedback considering reading speed.
- Play/pause and ±10s seek controls.
- Page advance/retreat without stopping or overloading TTS.
- Chapter + subchapter list parsed from the `.md` file.
- Remember last book and page; show per-book progress.
- Font size, font style, and theme picker (theme pipe is already wired — picker UI lives in `features/settings` later).
- Fade-off behavior for config/customize buttons while reading.
