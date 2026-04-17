This directory is supposed to be the dev enviroment for an app, which it's objective is to work like a natural voice TTS, it will get turned into a windows/android app at it's final goal, with pleasant user interface, being capable of running a light SOTA TTS algorythm which we will refine with time through research.

The following items are the requirements for the app and it's development plan is supposed to consider them all prior to carrying out implementations, but respecting the time order.

Early development (Setting-Focused):

- The title is always just "Vox".
- Capability to launch a dev enviroment with a Anthropic Minimalist UI.
- Take most of the screen in read mode, two pages, sweep all 2 at a time.
- The UI should be able to switch between library and book view.
- Capability to import, delete, rename, and organize books from md format.
- Capability to handle visual TTS word-by-word highlighting.
- Both time and the progress feedback, considering reading speed.
- Ability to play/pause and advance/retreat 10 seconds of text, like music players.
- Ability to advance/retreat pages without stopping or overloading the TTS.
- UI chapter and subchapters list taken from the md file.
- Ability to remember the last book and page read, also show books progress.
- Ability to change the font size, font style, and theme.
- Any config or customize buttons should fade off in reading mode.

Mid development (Research-Focused):

- Ability to identify or receive book covers.
- Ability to clean and sanitize epubs or pdf files prior to importing them.
- Ability to deliver high resolution TTS with a good voice quality.
- Ability to switch between voices, tones, and languages.
- Ability to run with no internet connection.
- Page skipping page animation.
- Bookmarking system.

Late development (Optmization/Usability-Focused)

- Has to be ram and processing efficient, but also execute smoothly.
- To run on both windows machine and android.
- Google Drive integration.
- Voice training and customization.
- Tag/Genre based categorization.