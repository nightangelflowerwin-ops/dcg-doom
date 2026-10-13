# DoomSol browser play package

This static package uses the existing modified Dwasm/PrBoom engine and bundled
FreeDoom Phase 1 assets. It is local browser gameplay, not CrocSwap DCG consensus.

Open index.html through an HTTP/HTTPS static host and press Play. No engine build,
wallet, Node installation or WSL is required for hosted visitors. Initial engine
downloads are about 32 MB. Desktop keyboard and a WebAssembly-capable browser
are required; touch/mobile support has not been verified.

For a local copy, serve this directory with `python -m http.server 18082 --bind
127.0.0.1`, then open http://127.0.0.1:18082/ . Double-clicking the HTML via file://
will not reliably load the WebAssembly assets.

The engine derives from https://github.com/GMH-Code/Dwasm and PrBoomX/PrBoom+,
with DoomSol agent additions. Retain ENGINE-LICENSE.txt and ENGINE-AUTHORS.txt.
The current engine source snapshot and upstream build instructions are included
in engine-source.zip. Rebuilding needs Emscripten and the upstream CMake setup;
it is not necessary to play. The source snapshot excludes unrelated training
data and game WADs. Obtain FreeDoom separately for source builds and use the
included GPL engine data sources to generate prboomx.wad as upstream documents.

FreeDoom assets: https://freedoom.github.io/ . Retain FREEDOOM-LICENSE.txt.
No commercial Doom IWAD is bundled. id Software's Doom inspired the engine;
this package does not imply endorsement by upstream projects or CrocSwap.
