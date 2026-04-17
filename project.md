This directory is supposed to be the dev enviroment for an app, which it's objective is to work like a natural voice TTS, it will get turned into a windows/android at it's final goal, with good html UI, being capable of running different TTS algorythms which we will implement with time through research.

1. Directory Setup & Architecture
    Adopt a Clean Architecture or Feature-Driven Development (FDD) pattern. This ensures that the heavy AI logic is decoupled from the UI, allowing you to swap TTS models without rebuilding the interface.

    Recommended Structure
        /core: Dependency injection, networking, and global utilities.

        /data: Repositories, local database (SQLite/Room) for library management, and file system handlers for PDFs/ePUBs.

        /domain: Business logic—entities like Book, Voice, and PlaybackState.

        /features:

            /reader: UI components for rendering text and handling highlighting.

            /tts: The engine layer (wrappers for local inference).

            /library: File picking and metadata extraction.

        /scripts: Python/Shell scripts for model quantization and optimization.

2. The UI/UX Foundation
The "magic" of ElevenReader is the synchronized highlighting. The UI must remain responsive while the audio plays.

    Rendering Engine: Use a robust PDF/ePUB renderer that provides access to glyph coordinates (e.g., PdfRenderer on Android or PDFKit on iOS).

    The Synchronizer: You need a mapping system that correlates audio timestamps with character offsets.

    Playback Controls: Implement a "Media Session" to allow users to control playback from the lock screen or via Bluetooth devices.

3. TTS Algorithm Research: Finding Local SOTA
To match ElevenLabs’ quality on a local machine, you must look into End-to-End Neural TTS models. Standard Concatenative TTS (robotic voices) will not suffice.

    Current State-of-the-Art (SOTA) for Local Execution
    Instruct your developer to research and benchmark the following:

    Piper: A fast, local neural TTS system that uses the VITS architecture. It is highly optimized for ARM devices (phones/Raspberry Pi).

    StyleTTS 2: Currently one of the highest-rated models for human-like prosody and emotion. It uses style-based latent variables to mimic natural speech patterns.

    Coqui TTS: An extensive toolkit that includes models like XTTS v2, which supports voice cloning and high-fidelity output.

    OpenVoice: Focused on instant voice cloning with low computational overhead.

    Key Technical Concepts to Explore
    VITS (Variational Inference with adversarial learning for end-to-end Text-to-Speech): Combines a generator and a predictor for high-quality audio in a single step.

    ONNX Runtime: This is critical. To run these models on-device, you must convert them to the ONNX (Open Neural Network Exchange) format to leverage hardware acceleration (NPU/GPU) without needing a full Python environment.

4. The Engineering Workflow: Text to Audio
The process isn't just "input text, output sound." It requires a pipeline:

    Text Normalization: Convert "10:00 AM" to "ten o'clock in the morning" and handle abbreviations.

    Phonemization: Convert text into phonemes (using espeak-ng or similar) to ensure the model knows exactly how to pronounce "read" vs. "read."

    Inference: Pass phonemes into the Neural Model (StyleTTS 2 or VITS).

    Vocoding: If using a two-stage model, a Vocoder (like HiFi-GAN) turns the spectrogram into actual wave files.

    Streaming: To reduce "Time to First Sound," the app should process text in chunks (sentences or paragraphs) rather than waiting for the whole chapter to generate.

5. Performance Optimization
Running SOTA models on mobile/local hardware is resource-intensive.

    Quantization: Reduce the model size from FP32 to INT8 or FP16. This significantly reduces memory footprint and increases speed with minimal loss in audio quality.

    Parallelization: Use multi-threading to ensure the UI thread is never blocked by the CPU-heavy inference task.

    Caching: Store generated audio for frequently read pages in a local cache directory to save battery.