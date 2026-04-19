# PR 7 Plan — Finish Early Dev Phase
 
## Context
 
PR 6 completed TTS playback (word highlighting, play/pause, ±10 s seek, progress bar). Three early-dev requirements remain open:
 
1. **Show per-book progress in library** — "remember last book and page, also show books progress" — library list shows no reading progress indicator today.
2. **Reading speed control** — no slider in the settings sheet to change TTS rate; `engine.setRate` exists but is never surfaced.
3. **Per-book cursor at block+char level** — `ReadingState` stores only `pageIndex`; mid-paragraph TTS position is lost on app restart.
4. **Voice/language selection** — no picker for TTS voice, silently always uses the engine default.
## Change Map
 
```
┌─────────────────────────────────────────────────────────────────────┐
│ ReadingState (lib/data/reading_state_repository.dart)               │
│  + blockIndex, charOffset, progressFraction                         │
│  + per-book map in JSON  { last, books:{path→state} }              │
│  + loadAllProgress() → Map<String,double>                           │
└──────────────────┬──────────────────────────────────────────────────┘
                   │ save / load
        ┌──────────┴───────────┐
        ▼                      ▼
AppShell (lib/app.dart)    LibraryView (lib/views/library_view.dart)
 + _currentPage/_block/     + bookProgress: Map<String,double>
   _charOffset / _fraction   + thin LinearProgressIndicator per tile
 + _onCursorChanged(...)
 + passes initialBlockIndex,
   initialCharOffset,
   onCursorChanged to BookView
 
        │
        ▼
BookView (lib/views/book_view.dart)
 + initialBlockIndex/charOffset params
 + onCursorChanged callback
 + calls playback.restoreCursor() after _load
 + calls onCursorChanged on _onPlaybackChanged
 + passes engine + controller to settings sheet
 
        │
        ▼
ReaderSettingsSheet (lib/views/reader/reader_settings_sheet.dart)
 + engine: TtsEngine, controller: PlaybackController params
 + Reading speed Slider (rate 0.25→1.0, shows WPM label)
 + Voice section: language dropdown + voice dropdown (FutureBuilder)
 
        │
        ▼
TtsEngine interface (lib/tts/tts_engine.dart)
 + getLanguages() / getVoices() / setLanguage() / setVoice()
 ↕ implemented by FlutterTtsEngine + NoopTtsEngine
 
PlaybackController (lib/tts/playback_controller.dart)
 + restoreCursor(blockIndex, charOffset)
 + reseedWps(double wps)
 
ReaderSettings (lib/core/reader_settings.dart)
 + speechRate: double (0.25–1.0, default 0.5)
```
 
## Detailed Steps
 
### 1. `lib/tts/tts_engine.dart`
 
Add four abstract methods after `setRate`:
```dart
Future<List<String>> getLanguages();
Future<List<Map<String, String>>> getVoices();
Future<void> setLanguage(String language);
Future<void> setVoice(Map<String, String> voice);
```
 
### 2. `lib/tts/noop_tts_engine.dart`
 
Implement the four new methods — `getLanguages` → `[]`, `getVoices` → `[]`, `setLanguage`/`setVoice` → no-ops.
 
### 3. `lib/tts/flutter_tts_engine.dart`
 
Implement the four methods delegating to `_tts.getLanguages()`, `_tts.getVoices()`, `_tts.setLanguage()`, `_tts.setVoice()`. Cast the voice map from `dynamic` to `Map<String,String>`.
 
### 4. `lib/tts/playback_controller.dart`
 
Add two methods:
```dart
void restoreCursor(int blockIndex, int charOffset) {
  _cursorBlockIndex = blockIndex.clamp(0, _blocks.length);
  _cursorCharOffset = charOffset;
  notifyListeners();
}
 
void reseedWps(double wps) {
  _wordsPerSecond = wps;
  _spokenWordsForWps = 0;
  _spokenClock.reset();
  notifyListeners();
}
```
 
### 5. `lib/core/reader_settings.dart`
 
Add `speechRate: double` (default 0.5) with `setSpeechRate(double rate)` method — pattern identical to `setScale`.
 
### 6. `lib/data/reading_state_repository.dart`
 
**`ReadingState`** — add three optional fields with defaults:
```dart
const ReadingState({
  required this.bookPath,
  required this.pageIndex,
  this.blockIndex = 0,
  this.charOffset = 0,
  this.progressFraction = 0.0,
});
```
Update `toJson` and `fromJson` (new fields default to 0/0.0 if absent — handles old format gracefully).
 
**File format** changes from a single flat object to:
```json
{ "last": "path", "books": { "path": { "pageIndex":0, "blockIndex":0, "charOffset":0, "progressFraction":0.0 } } }
```
 
Migration: if `load()` reads an object that has `bookPath` at top level (old format), treat it as a single-entry `books` map with the existing `pageIndex`.
 
**`ReadingStateRepository`** abstract class — add:
```dart
Future<Map<String, double>> loadAllProgress();
```
 
**`FileSystemReadingStateRepository`**:
- `load()` — reads new format, falls back to old, returns the `books[last]` entry as `ReadingState`
- `loadAllProgress()` — returns `{ path: progressFraction }` for all entries in `books`
- `save(ReadingState state)` — updates `books[state.bookPath]` and `last`
### 7. `lib/views/reader/reader_settings_sheet.dart`
 
Signature change:
```dart
Future<void> showReaderSettingsSheet(
  BuildContext context, {
  required ReaderSettings settings,
  required ThemeController theme,
  required TtsEngine engine,
  required PlaybackController controller,
})
```
 
New **Reading speed** row below Font family, before Theme:
- `Slider` with `min:0.25`, `max:1.0`, `divisions:6`
- Label: `'${(state._speechRate * 300).round()} WPM'` (rate×5 wps × 60)
- On change: `settings.setSpeechRate(v)` + `engine.setRate(v)` + `controller.reseedWps(v * 5.0)`
- Initial value from `settings.speechRate`
New **Voice** section at bottom (only shown when voices are available):
- `_languagesFuture` and `_voicesFuture` loaded in `initState` via `engine.getLanguages()` / `engine.getVoices()`
- `FutureBuilder` wraps the section; while loading shows nothing (not a spinner)
- Language `DropdownButton<String>` — calls `engine.setLanguage(lang)` on change; filters voice list to matching locale
- Voice `DropdownButton<String>` (display `voice['name']`) — calls `engine.setVoice(voice)` on change
- If both lists empty (NoopEngine), entire voice section is hidden
### 8. `lib/views/book_view.dart`
 
Add params to `BookView`:
```dart
final int initialBlockIndex;   // default 0
final int initialCharOffset;   // default 0
final void Function(int blockIndex, int charOffset, double progressFraction)? onCursorChanged;
```
 
In `_load()`, after `_playback.updateBlocks(blocks)`:
```dart
if (widget.initialBlockIndex > 0 || widget.initialCharOffset > 0) {
  _playback.restoreCursor(widget.initialBlockIndex, widget.initialCharOffset);
}
```
 
In `_onPlaybackChanged()`, after the auto-follow logic, add:
```dart
widget.onCursorChanged?.call(
  _playback.cursorBlockIndex,
  _playback.cursorCharOffset,
  _playback.progress,
);
```
 
In `_openSettings()`, pass `engine` and `controller`:
```dart
await showReaderSettingsSheet(
  context,
  settings: widget.settings,
  theme: widget.theme,
  engine: widget.ttsEngine,
  controller: _playback,
);
```
 
### 9. `lib/views/library_view.dart`
 
Add optional param `Map<String, double> bookProgress = const {}` to `LibraryView`.
 
In `_buildBody`, replace each `ListTile` subtitle with a `Column` that conditionally appends a 2 px `LinearProgressIndicator`:
```dart
subtitle: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(p.basename(book.path)),
    if ((bookProgress[book.path] ?? 0.0) > 0.01)
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: LinearProgressIndicator(
          value: bookProgress[book.path],
          minHeight: 2,
        ),
      ),
  ],
),
```
 
### 10. `lib/app.dart`
 
`_AppShellState` additions:
- `int _currentPage = 0`, `int _currentBlockIndex = 0`, `int _currentCharOffset = 0`, `double _currentFraction = 0.0`
- `Map<String, double> _bookProgress = const {}`
`_boot()` — after building `saved`, call:
```dart
_bookProgress = await widget.stateRepository.loadAllProgress();
```
 
`_open(book)` — reset cursor fields to 0; restore from `_bookProgress` (page only — block/char defaults to 0 for a fresh open).
 
`_onPageChanged(int page)`:
```dart
_currentPage = page;
widget.stateRepository.save(ReadingState(
  bookPath: book.path,
  pageIndex: page,
  blockIndex: _currentBlockIndex,
  charOffset: _currentCharOffset,
  progressFraction: _currentFraction,
));
```
 
Add `_onCursorChanged(int blockIndex, int charOffset, double fraction)`:
```dart
_currentBlockIndex = blockIndex;
_currentCharOffset = charOffset;
_currentFraction = fraction;
_bookProgress = Map.of(_bookProgress)..[book.path] = fraction;
// fire-and-forget save
widget.stateRepository.save(ReadingState(
  bookPath: book.path,
  pageIndex: _currentPage,
  blockIndex: blockIndex,
  charOffset: charOffset,
  progressFraction: fraction,
));
```
 
`build()` — pass new fields to `BookView` and `bookProgress` to `LibraryView`.
 
## Test Updates
 
### `test/playback_bar_test.dart` + `test/playback_controller_test.dart`
 
Both `_FakeEngine` classes need the four new methods:
```dart
@override Future<List<String>> getLanguages() async => [];
@override Future<List<Map<String, String>>> getVoices() async => [];
@override Future<void> setLanguage(String language) async {}
@override Future<void> setVoice(Map<String, String> voice) async {}
```
 
`test/playback_controller_test.dart` — add two new test cases:
```
'restoreCursor seeds the block+char offset'
'reseedWps resets elapsed time estimate'
```
 
### `test/widget_test.dart`
 
`_FakeStateRepo` — add:
```dart
@override
Future<Map<String, double>> loadAllProgress() async => const {};
```
 
Add one new test:
```
'Library shows a progress bar for a book with saved progress'
— constructs _FakeStateRepo with a preloaded progress map via a custom implementation,
  boots the app, confirms LinearProgressIndicator appears for the book with progress > 0.
```
 
(Alternatively, test that `onCursorChanged` triggers a `save` call — simpler to wire.)
 
## Verification
 
1. `flutter analyze` — must report no issues
2. `flutter test` — all tests pass (44 existing + ~4 new = ~48)
3. Manual smoke test (web or desktop):
   - Open a book, start TTS, let it advance 10+ blocks, navigate back to library — progress bar should appear on that book's tile
   - Re-open the book — TTS should resume from near where it stopped (block-level)
   - Open settings sheet — Reading speed slider renders; dragging it changes WPM label; voice dropdowns appear if the platform has voices