# Vox dev environment — status tracker

## 2026-04-18 — PR 5: two-page reader + line-break fix + bundled early-dev items

### Done
- **Line-break fix (feedback).** `lib/core/markdown/block_parser.dart` now joins consecutive non-blank lines with `'\n'` instead of `' '`, so the author's soft breaks survive into render. `test/block_parser_test.dart` updated + new `'line1\nline2\n\nline3'` case.
- **Pagination + two-page spread (feedback).** New `lib/views/reader/paginator.dart`: `ReaderTextStyles`, `PagePiece`, `ReaderPage`, `paginateBlocks(...)`. Uses `TextPainter` to measure blocks at the target page size, bin-packs, splits long paragraphs at the nearest whitespace boundary via `getPositionForOffset`. Strips leading blanks at page start. Also `findSpreadForBlock(...)` for TOC navigation. New `lib/views/reader/reader_page_view.dart` renders one `ReaderPage` with the same `ReaderTextStyles`.
- `lib/views/book_view.dart` — major rewrite. `LayoutBuilder` derives per-page size. Breakpoint `maxWidth >= 720` → two pages side-by-side, 24 px gutter; narrower → single page. `PageView.builder` holds the spreads; `PageController` persists across rebuilds. Pagination cache keyed on `(pageSize, fontScale, fontFamily, themeMode, blocks.length)` so resizes / setting changes recompute once.
- **TOC drawer.** New `lib/core/markdown/toc.dart` → `TocEntry { level, title, blockIndex, depth }` + `buildToc(blocks)`. AppBar action `Icons.menu_book` opens the end-drawer; tapping an entry calls `PageController.animateToPage(findSpreadForBlock(...))`.
- **Reader settings sheet.** New `lib/core/reader_settings.dart` — `ReaderSettings extends ChangeNotifier` with `fontScale` (S/M/L/XL, multipliers 0.85/1.0/1.15/1.3) and `fontFamily` (Serif/Sans/System). New `lib/views/reader/reader_settings_sheet.dart` is a modal bottom sheet with three `SegmentedButton`s (size, family, theme). AppBar action `Icons.tune`. Paginator recomputes when any of these change.
- **Remember last book + page.** New `lib/data/reading_state_repository.dart` — abstract + `FileSystemReadingStateRepository` writing `<app-docs>/Vox/.state.json`. `AppShell` loads state on boot, auto-selects the last book if it still exists in the library (else silently falls back to the library). `BookView` saves on open and on every `PageView.onPageChanged`.
- **Fade-off AppBar in reading mode.** `BookView` tracks `_chromeVisible` + a 3 s `Timer`. AppBar wrapped in `AnimatedOpacity` + `IgnorePointer`. Tapping the reader body toggles chrome; opening/closing the settings sheet re-arms the timer. Loading / error / empty states keep chrome visible.
- **Delete + rename books.** `LibraryRepository` gained `delete` and `rename`. `FileSystemLibraryRepository.rename` validates the name (non-empty, no `/`\`:`), preserves the file extension, and re-reads the title from the first `# ` line. Each library `ListTile` now has a trailing `PopupMenuButton` (tooltip "More") with Rename / Delete; rename uses a `TextField` dialog with live validation, delete uses a confirm dialog. Errors surface through `ScaffoldMessenger`.
- **Styles normalization.** `BookView._stylesFor` merges `DefaultTextStyle` into the theme styles and sets `inherit: false`, so the paginator's `TextPainter` measurements match what the tree actually renders. A 24 px safety margin is subtracted from each page's content height to absorb small layout-vs-measurement drift.
- Verified locally: `flutter analyze` (no issues), `flutter test` (28/28 pass — 7 block_parser + 5 paginator + 4 toc + 12 widget).

### Not yet done
- Windows desktop build still blocked by the MSVC linker errors from PR 3 (environment, not code).
- Android toolchain — end-term goal.
- Reading progress indicator (time-left + % read) — needs reading-speed estimation; lands with the TTS work.

### Next up — PR 6
- **TTS engine bootstrap.** Add a TTS service (native platform bridges — `flutter_tts` on mobile/web, `package:flutter_tts` windows impl or `win32` SAPI direct for desktop). Word-level highlighting in the paginator's current `PagePiece` model (paragraphs become `TextSpan` runs). Play/pause + ±10 s seek in a bottom control bar (fades with AppBar). Page-advance that doesn't interrupt speech. Reading-speed-based progress indicator.

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Two-page layout ✅ (PR 5) · chapter + subchapter list ✅ (PR 5) · remember last book and page ✅ (PR 5) · font/theme picker ✅ (PR 5) · fade-off chrome ✅ (PR 5) · delete/rename/organize ✅ (PR 5, partial — "organize" beyond rename/delete still TBD).
- Word-by-word TTS highlighting — PR 6.
- Play/pause and ±10 s seek — PR 6.
- Page advance/retreat without stopping TTS — PR 6.
- Reading-speed progress indicator — PR 6.

---

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
