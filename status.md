# Vox dev environment — status tracker

## 2026-04-19 — Hotfix: dual reading view modes

### Done
- **Implemented two persistent page-view modes.** `lib/views/book_view.dart` now supports `track` mode (page follows TTS cursor) and `fixed` mode (page stays where user moved it while TTS continues processing).
- **Track mode exits only on user page navigation.** Manual page flips/scrubs switch to fixed mode; automatic playback-driven page flips remain in track mode.
- **Added explicit return-to-track control in bottom bar.** `lib/views/reader/playback_bar.dart` now includes the requested lines+triangle control that re-enables track mode when currently fixed.
- **Contents and settings remain independent overlays.** Mode switching is page-view behavior only and does not stop or pause the TTS controller.
- **Test coverage expanded.** `test/playback_bar_test.dart` now verifies the track-mode button callback path.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `54/54`.

### Not yet done
- Optional enhancement: persist selected view mode per book/session so app restarts restore the user’s last track/fixed preference.

## 2026-04-19 — Hotfix: markdown hard-break support

### Done
- **Added explicit hard line-break handling while keeping adaptive prose reflow.** `lib/core/markdown/block_parser.dart` now preserves a line break inside paragraphs only when markdown hard-break markers are present.
- **Supported hard-break markers.** Two trailing spaces before newline (`"line  \n"`) and trailing backslash (`"line\\\n"`) now emit an internal `\n` in paragraph text.
- **Default behavior preserved for normal prose.** Unmarked line wraps still join with spaces and reflow with font/layout changes.
- **Test coverage expanded.** `test/block_parser_test.dart` now includes cases for both hard-break syntaxes and mixed marked/unmarked paragraph behavior.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `53/53`.

### Not yet done
- Optional future enhancement: dedicated per-book rendering mode toggle (prose vs verse) for stricter formatting control.

## 2026-04-19 — Hotfix: adaptive paragraph reflow

### Done
- **Paragraph lines now reflow adaptively with font/layout changes.** `lib/core/markdown/block_parser.dart` now joins consecutive non-blank lines with spaces instead of forced `\n` breaks.
- **Page count can now decrease when text fits more per line.** Reader pagination is no longer pinned to source line-wrap positions for normal paragraphs.
- **Tests updated for new parser behavior.** `test/block_parser_test.dart` now expects paragraph line-join reflow semantics.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `50/50`.

### Not yet done
- Optional future enhancement: support explicit hard line-break markdown semantics (for poetry/verse) while keeping default prose reflow.

## 2026-04-19 — Hotfix: contained font-family matrix

### Done
- **Font-family selector now stays inside the settings panel.** Replaced the horizontal segmented control with a fixed `3x2` in-panel matrix in `lib/views/reader/reader_settings_sheet.dart`.
- **Rounded-corner tile style applied.** Each family option now uses a 4-corner rounded button (12 px radius) with selected/unselected styling aligned to existing theme tokens.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `50/50`.

### Not yet done
- Optional polish: preview each font family in its own button text (currently labels use the panel text style for consistency).

## 2026-04-19 — Hotfix: expanded reading fonts

### Done
- **Reader font choices expanded to reading-focused families only.** `lib/core/reader_settings.dart` now offers: Times New Roman, Georgia, Garamond, Cambria, Sans Serif, and Verdana.
- **Requested families included explicitly.** "Times New Roman" and "Sans Serif" are now first-class options in the reader settings panel.
- **Default family updated.** New default reader font is `Times New Roman`.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `50/50`.

### Not yet done
- Optional future step: platform-specific font fallback chains (to avoid visual differences when a family is unavailable on a device).

## 2026-04-19 — Hotfix: import-selected-books library flow

### Done
- **Library now supports selecting files instead of picking a source folder.** `LibraryRepository` gained `importBooks()` and `LibraryView` now triggers file import via the `Import books` action.
- **Imported files are persisted in a dedicated library folder.** `lib/data/library_folder.dart` now defaults to `Documents/VoxLibrary` on Windows when available (fallback to app documents on other platforms).
- **Import copies `.md` files into library storage.** `lib/data/library_repository.dart` now opens a multi-file picker, copies selected files, and auto-resolves duplicate names using `name (n).md`.
- **Library empty state and toolbar copy updated.** UI now explains import-and-persist behavior and points users to the managed library folder.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `48/48`.

### Not yet done
- Folder-selection flow is still present in the repository abstraction for backward compatibility, but the active UI now uses import-first workflow.

## 2026-04-19 — Hotfix: left-floating panel + 6-book row

### Done
- **Settings panel corrected to physical left.** `lib/views/reader/reader_settings_sheet.dart` now anchors with `Positioned(left: ...)` to avoid ambiguous side placement.
- **Floating visual vibe added.** Settings now render as a rounded floating card with shadow, inset top/bottom margins, and slide+fade+slight-scale transition.
- **Library now targets 6 books per row on desktop.** `lib/views/library_view.dart` uses width breakpoints with `6` columns for wide layouts (`>= 980 px`), with smaller responsive fallbacks.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `48/48`.

### Not yet done
- Final cover rendering (image thumbnails/spines) is still pending; current book tiles remain placeholders.

## 2026-04-19 — Hotfix: library book-card grid

### Done
- **Library front view now uses book-like cards instead of list rows.** `lib/views/library_view.dart` switched to a responsive `GridView.builder` with up to 4 columns.
- **Card shape and layout prepared for covers.** Each entry now renders as a portrait tile (`childAspectRatio: 0.72`) with a placeholder cover area, title, file name, and per-book progress strip.
- **Actions preserved per item.** Rename/delete remain available from each card via the same `More` popup menu.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `48/48`.

### Not yet done
- Real cover thumbnails are not wired yet; cards currently use a styled placeholder area for upcoming cover integration.

## 2026-04-19 — Hotfix: left-side settings panel

### Done
- **Settings now opens from the left as a pop panel.** `lib/views/reader/reader_settings_sheet.dart` switched from `showModalBottomSheet` to `showGeneralDialog` with a slide-in transition from the left.
- **Backdrop still fades while reading UI stays visible behind it.** The dialog now uses a dim barrier (`Colors.black54`) and dismiss-on-backdrop behavior.
- **All configs remain accessible in one panel.** The settings content is now full-height with an internal `Expanded + SingleChildScrollView`, plus a header and close button.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `48/48`.

### Not yet done
- Optional polish: add a compact desktop-only visual style variant (e.g., stronger panel border/shadow theming and section grouping cards).

## 2026-04-19 — Hotfix: settings sheet bounds + TTS debug modes

### Done
- **Reader settings sheet now has explicit size restraints.** `lib/views/reader/reader_settings_sheet.dart` now uses `showModalBottomSheet(... useSafeArea: true, constraints: BoxConstraints(maxWidth: 760))` and wraps content in `SizedBox(height: viewport * 0.9)`. This prevents lower controls from rendering outside the screen.
- **Overflow-proof segmented controls.** Font-size, font-family, and theme segmented controls are each wrapped in horizontal `SingleChildScrollView` containers so narrow layouts no longer clip controls.
- **TTS crash debugging harness added.** New `lib/tts/simulated_tts_engine.dart` (event-driven mock engine) and `lib/tts/logging_tts_engine.dart` (call/event tracing). `lib/main.dart` now supports `--dart-define=VOX_TTS=real|mock|noop` and `--dart-define=VOX_TTS_TRACE=true` for side-by-side reproduction.
- **Debug docs added.** `README.md` now includes copy-paste commands for mock vs real TTS crash isolation and trace interpretation.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `47/47`.

### Not yet done
- Desktop-specific visual restyling of the settings sheet (if a less mobile-style container/chrome is desired) is not implemented in this hotfix.
- Persisting the selected runtime TTS mode between launches is not implemented (current mode selection is intentionally runtime-flag based for debugging).

## 2026-04-19 — Hotfix: playback crash-hardening

### Done
- **Chunked utterance playback to reduce native TTS stress.** `lib/tts/playback_controller.dart` now sends at most 280 chars per `speak` call, cut on whitespace where possible. This avoids handing very large paragraph strings to the Windows TTS plugin at once.
- **Completion fallback when boundary callbacks are missing.** On each `TtsCompleted`, cursor progress is now advanced by the utterance chunk length if no boundary events arrived, then playback continues in the same block until fully consumed. This prevents stalls and keeps progress monotonic.
- **Safer engine auto-selection in debug.** `lib/main.dart` now accepts `VOX_TTS=auto` (default) and resolves to `mock` on Windows debug builds, `real` otherwise. Explicit `VOX_TTS=real|mock|noop` still overrides this.
- **Regression test coverage.** `test/playback_controller_test.dart` gained a long-block test that verifies chunking and completion-only advancement behavior.
- **Validation complete.** `flutter analyze` reports no issues; `flutter test` passes `48/48`.

### Not yet done
- If a hard native process crash still occurs specifically in `VOX_TTS=real` mode after chunking, the next step is isolated plugin-level reproduction and native crash dump capture.

## 2026-04-18 — PR 6: TTS bootstrap + word highlight + playback bar

### Done
- **TTS engine interface + events.** New `lib/tts/tts_engine.dart` — sealed `TtsEvent` hierarchy (`TtsStarted`/`TtsBoundary(startChar,endChar)`/`TtsCompleted`/`TtsPaused`/`TtsCancelled`/`TtsError`) + abstract `TtsEngine { events, speak, pause, resume, stop, setRate, dispose }`. Keeps the reader decoupled from any one TTS package.
- **Engine implementations.** `lib/tts/noop_tts_engine.dart` for tests / unsupported platforms. `lib/tts/flutter_tts_engine.dart` wraps `flutter_tts ^4.2.0` — wires start/completion/pause/cancel/error/progress handlers (progress → `TtsBoundary`), emits to a broadcast stream, uses `awaitSpeakCompletion(true)`. Added `flutter_tts` to `pubspec.yaml`.
- **PlaybackController.** New `lib/tts/playback_controller.dart` — `ChangeNotifier` owning `_blocks`, `_pages`, `_wordRangesByBlock` (via `RegExp(r'\S+')`), `_cursorBlockIndex`/`_cursorCharOffset`, `_currentWordRange`, `_wordsPerSecond` (EMA α=0.3 after 30 words + 20 s of observed speech). Commands: `togglePlayPause`, `play`, `pause`, `stop`, `seek(Duration)` (converts to words via WPS, stops engine, advances/rewinds, re-speaks if was playing), `jumpToBlock`, `updateBlocks`, `updatePages`. Skips `BlockKind.blank` + empty blocks on playback. Exposes `wordsSpoken`, `progress`, `elapsed`, `estimatedTotal`, `atStart`, `atEnd`.
- **Paginator piece offsets.** `PagePiece` gained `blockCharOffset`, `ReaderPage` gained `pieceBlockIndexes: List<int?>` (parallel to `pieces`, `null` for blank spacers). Paragraph splits now track `consumed = text.length - split.$2.length` so the second piece's characters still map back into the source block — required for word highlighting across page breaks.
- **Reader highlight.** `ReaderPageView` accepts `highlightBlockIndex` + `highlightRange`. For the paragraph piece that owns the currently-spoken word, renders `SelectableText.rich` with three `TextSpan`s (before / highlight / after), the middle span using `TextStyle(backgroundColor: primary.withValues(alpha: 0.22))`. Other pieces keep the cheap `SelectableText` path.
- **PlaybackBar.** New `lib/views/reader/playback_bar.dart` — thin progress bar + elapsed/estimated time labels, then five `IconButton`s in a row: `skip_previous` (Previous page) · `replay_10` (Replay 10 seconds) · `play_circle`/`pause_circle` (Play/Pause, 36 px) · `forward_10` (Forward 10 seconds) · `skip_next` (Next page). Built with `AnimatedBuilder` listening to the controller so labels/icons stay in sync.
- **BookView wiring.** `BookView` takes a `TtsEngine` and owns a `PlaybackController`. Blocks are pushed into the controller on load; pages are pushed on every `_paginate` call (identity-check guard avoids stomping the cursor on repeated builds). PageView is wrapped in `AnimatedBuilder(animation: _playback)` so the highlight re-paints on boundary events. Auto-follow: when the cursor crosses a page boundary, PageView `animateToPage`s to the spread containing the block; tapping Previous/Next page suspends auto-follow for 600 ms so the user's jump sticks. Bar lives in `bottomNavigationBar` and fades with the AppBar (`AnimatedOpacity + IgnorePointer`, same `_chromeVisible` toggle).
- **Engine plumbed through the tree.** `VoxApp` + `AppShell` accept an optional `TtsEngine`, default to `NoopTtsEngine` (test-safe). `main.dart` constructs `FlutterTtsEngine()` for real runs. Engine is owned by `_VoxAppState` and disposed with the app.
- **Tests.** New `test/playback_controller_test.dart` (7 cases: totalWords, `seek(+10s) = 25` words at default WPS, `seek(-10s)` clamp, cross-block seek, `TtsCompleted` advances past blanks, `updatePages` preserves cursor, `TtsBoundary` advances offset). New `test/reader_page_view_test.dart` (plain paragraph path; 3-span highlight; split-piece highlight respects `blockCharOffset`). New `test/playback_bar_test.dart` (all five icons render; play ↔ pause toggle; previous/next don't call `speak`; forward_10 advances; replay_10 rewinds). `test/paginator_test.dart` updated for the new `ReaderPage` constructor + a "second piece has offset" case.
- Verified locally: `flutter analyze` (no errors), `flutter test` (44/44 pass).

### Not yet done
- Windows desktop build still blocked by the MSVC linker errors from PR 3 (environment, not code) — so real-device TTS hasn't been exercised here yet.
- Android toolchain — end-term goal.
- TTS rate exposure in the settings sheet — still ties to `FlutterTts.setSpeechRate` but no UI control yet; the EMA handles the feedback loop.

### Next up — PR 7
- Hook TTS rate into the reader settings sheet; surface a "reading speed" slider that calls `engine.setRate` + re-seeds `initialWordsPerSecond`.
- Per-book persisted cursor (block + char offset) so resume restores mid-paragraph, not just the spread.
- Cross-platform voice pick (locale + voice name), remembered in settings.

### Remaining Early-development (Setting-Focused) work — from `project.md`
- Two-page layout ✅ (PR 5) · chapter + subchapter list ✅ (PR 5) · remember last book and page ✅ (PR 5, spread-level) · font/theme picker ✅ (PR 5) · fade-off chrome ✅ (PR 5, now also fades the playback bar) · delete/rename ✅ (PR 5).
- Word-by-word TTS highlighting ✅ (PR 6).
- Play/pause and ±10 s seek ✅ (PR 6).
- Page advance/retreat without stopping TTS ✅ (PR 6 — page buttons suspend auto-follow without calling stop/speak).
- Reading-speed progress indicator ✅ (PR 6 — EMA-driven `elapsed` + `estimatedTotal` on the bar).

---

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
