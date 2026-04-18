# Vox dev environment — status tracker

## 2026-04-18 — PR 3: library lists `.md` books from a folder

### Done
- `pubspec.yaml` — added `file_picker ^8.0.0`, `path_provider ^2.1.0`, `path ^1.9.0`.
- `lib/models/book.dart` — immutable `Book { path, title }` with value-equality.
- `lib/data/library_folder.dart` — thin wrapper over `path_provider` + `file_picker`. Defaults to `<app-docs>/Vox/` (auto-created, works on both Windows and Android without a runtime permission prompt). `pick()` opens the native folder picker and caches the result.
- `lib/data/library_repository.dart` — `LibraryRepository` interface + `FileSystemLibraryRepository` implementation. Lists `.md` files (case-insensitive extension), reads the first `# ` line as the title, falls back to the filename stem; unreadable files are skipped silently. Sorted alphabetically, case-insensitive.
- `lib/views/library_view.dart` — now a `StatefulWidget` that async-loads books, with distinct loading / error / empty / list states. `AppBar` has a `folder_open` action for re-picking the folder. Empty state surfaces the active folder path and offers a picker shortcut.
- `lib/views/book_view.dart` — takes a `Book` and renders `book.title` as the placeholder body. Back-arrow tooltip preserved so the round-trip test still works.
- `lib/app.dart` — `VoxApp` now accepts an optional `LibraryRepository` (defaults to `FileSystemLibraryRepository`) for test injection. `AppShell` holds the currently-selected `Book` and forwards it to `BookView`.
- `test/widget_test.dart` — rewritten with a `_FakeRepo` to avoid touching disk: (1) boot shows "Vox" + both book titles, (2) empty folder hint renders with the folder path, (3) Library → Book → Library round-trip shows the tapped book's title and comes back to the full list.
- Verified locally: `flutter pub get`, `flutter analyze` (no issues), `flutter test` (3/3 pass).

### Not yet done
- Windows desktop build still blocked by MSVC linker errors against `libcpmtd.lib` / missing UCRT debug symbols — unrelated to this PR's code (Chrome preview of PR 2 worked). Retry after forcing MSVC 14.44 via `CMAKE_GENERATOR_TOOLSET`, or wait for a Flutter patch.
- Android runner still not generated locally (no Android toolchain installed). Android support stays an end-term goal per project.md.
- Persisting the chosen folder across launches — arrives with the "remember last book and page" bullet.

### Next up — PR 4
- **Render book content.** Load the selected `.md` from disk, parse it, and display. Start minimal: plain-text scroll view with `flutter_markdown` (or a hand-rolled parser if we want to keep deps tight). Still no TTS, no two-page layout, no chapter list.

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Delete / rename / organize books (listing half is now done — PR 3).
- Two-page read layout that fills most of the screen, sweeping two pages at a time.
- Word-by-word TTS highlighting.
- Time + progress feedback considering reading speed.
- Play/pause and ±10s seek controls.
- Page advance/retreat without stopping or overloading TTS.
- Chapter + subchapter list parsed from the `.md` file.
- Remember last book and page; show per-book progress.
- Font size, font style, and theme picker (theme pipe already wired — picker UI lands in a settings view).
- Fade-off behavior for config/customize buttons while reading.
