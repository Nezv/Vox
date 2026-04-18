# Vox dev environment — status tracker

## 2026-04-18 — PR 4: render selected book content

### Done
- `lib/core/markdown/block_parser.dart` — hand-rolled minimal parser. `Block { BlockKind kind, String text }` with value-equality; `parseMarkdownBlocks(source)` handles `#`/`##`/`###` headings, paragraph joins (consecutive non-blank lines → one block), and blank-line collapse (runs of blanks → one `BlockKind.blank`). No inline emphasis / lists / links — those arrive with the reader-formatting PR.
- `lib/data/book_content_repository.dart` — `BookContentRepository` interface + `FileSystemBookContentRepository` that `await File(path).readAsString()`. Mirrors the `LibraryRepository` shape for test injection.
- `lib/views/error_state.dart` — lifted the old `_ErrorState` out of `library_view.dart` so `BookView` and `LibraryView` share one widget (custom title prop).
- `lib/views/book_view.dart` — now a `StatefulWidget`. `initState` → `_load()` reads content via the repo and parses into blocks. Four states: loading spinner, error (shared `ErrorState` with Retry, title "Couldn't open book"), empty (`Text('Empty book')` when no non-blank blocks), loaded (`ListView.builder` with `EdgeInsets.symmetric(horizontal: 32, vertical: 24)` padding, rendering h1/h2/h3 as scaled `Text`, paragraphs as `SelectableText` so quotes can be copied, blanks as 16 px spacers). AppBar and back-arrow tooltip unchanged so the round-trip test still works.
- `lib/app.dart` — `VoxApp` now takes an optional `BookContentRepository` (defaults to `FileSystemBookContentRepository()`), threaded through `AppShell` into `BookView`.
- `test/block_parser_test.dart` — 7 unit tests covering empty input, heading levels, paragraph joining, blank-line collapse, heading-between-paragraphs, 4-hash fallback, and trailing-blank trimming.
- `test/widget_test.dart` — added `_FakeContentRepo` with an `errors` map + read counter. Round-trip test now asserts parsed content (`First para.`, `Section`, `Second para.`) renders. New tests: error state + Retry re-invokes `read`; empty `.md` shows the "Empty book" hint.
- Verified locally: `flutter analyze` (no issues), `flutter test` (12/12 pass).

### Not yet done
- Windows desktop build still blocked by the MSVC linker errors from PR 3 (unrelated to this PR's code).
- Android toolchain — end-term goal.

### Next up — PR 5
- Pick from the Early-development list — strongest candidates are the two-page read layout (sweeping two pages at a time) or the chapter + subchapter list parsed from the `.md`. Defer the exact pick to the PR 5 `/ultraplan`.

---

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

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Delete / rename / organize books (listing half done in PR 3; render half done in PR 4).
- Two-page read layout that fills most of the screen, sweeping two pages at a time.
- Word-by-word TTS highlighting.
- Time + progress feedback considering reading speed.
- Play/pause and ±10s seek controls.
- Page advance/retreat without stopping or overloading TTS.
- Chapter + subchapter list parsed from the `.md` file.
- Remember last book and page; show per-book progress.
- Font size, font style, and theme picker (theme pipe already wired — picker UI lands in a settings view).
- Fade-off behavior for config/customize buttons while reading.
