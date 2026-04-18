# Vox dev environment — status tracker

## 2026-04-17 — PR 2: library ↔ book view shell

### Done
- `lib/views/library_view.dart` — minimal `Scaffold` with "Library" heading, `AppBar` titled "Vox", and an "Open sample" `TextButton` that fires an `onOpen` callback.
- `lib/views/book_view.dart` — `Scaffold` with "Vox" `AppBar`, back-arrow `IconButton` (tooltip "Back to library") firing `onBack`, and a "Book" placeholder body.
- `lib/app.dart` refactored: replaced `HomeScaffold` (PR 1's theme-cycler demo) with `AppShell`, a `StatefulWidget` holding `enum View { library, book }` and swapping views via `setState`. No routing package yet — a single enum is enough until routes multiply.
- Theme infrastructure from PR 1 (`AppTheme` light/dark/sepia + `ThemeController`) stays wired under `VoxApp`, just not exposed in the UI; the settings picker will consume it later.
- Removed `lib/features/*/.gitkeep` stubs from PR 1 — the approved PR 2 architecture uses `lib/views/` for navigation-level widgets instead.
- `test/widget_test.dart` rewritten: boot asserts "Vox" in `AppBar` + "Library" body + "Open sample" button; a second test exercises Library → Book → Library round-trip.
- `README.md` now documents prerequisites (Flutter 3.22+, Android toolchain, VS 2022 C++ workload), the one-time `flutter create .` step, and run / test commands.

### Not yet done (still blocking local verification)
- Flutter SDK is **not installed** on this machine, so `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run` have not been executed. The test file compiles logically against the public API it imports, but has not been run.
- `android/` and `windows/` platform runners are still not generated. Run `flutter create --project-name vox --org com.vox --platforms=windows,android .` from the repo root after installing Flutter — it will fill them in without touching `lib/`, `test/`, or the docs.

### Next up — PR 3 (first bullet of remaining Early-development work)
- Library view lists `.md` books from a user-chosen folder: file-system permission on Android, folder picker or conventional `~/Documents/Vox/` on Windows, titles derived from the first H1 in each file (fallback: filename). Still no rendering — that's PR 4.

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Import / delete / rename / organize `.md` books (PR 3 starts the listing half of this).
- Two-page read layout that fills most of the screen, sweeping two pages at a time.
- Word-by-word TTS highlighting.
- Time + progress feedback considering reading speed.
- Play/pause and ±10s seek controls.
- Page advance/retreat without stopping or overloading TTS.
- Chapter + subchapter list parsed from the `.md` file.
- Remember last book and page; show per-book progress.
- Font size, font style, and theme picker (theme pipe already wired — picker UI lands in a settings view).
- Fade-off behavior for config/customize buttons while reading.
