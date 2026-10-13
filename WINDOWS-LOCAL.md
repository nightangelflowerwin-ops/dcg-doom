# Windows local development

This fork provides two local paths, with no paid hosting required.

## Windows browser and relay sandbox

Double-click `Start-Windows-Local.cmd`. Requires Node.js 20 or newer.
Close the launcher or press Ctrl+C to stop it.

The page is at http://127.0.0.1:18080/doom-play/?relayer=http://127.0.0.1:18787.
Join through the page to exercise signed inputs, sessions and frame decoding.
This is upstream's mock mode: synthetic frame data, not a playable Doom engine.
Only the web directory is served; both listeners bind to this computer's loopback address.

## Actual Doom engine replay under WSL Ubuntu

Requires Git, curl, make and a C compiler inside WSL. From this checkout in WSL:

```sh
DOOM_SCRATCH="$PWD/.cache/doom-scratch" sh stunts/doom-host/build.sh
mkdir -p out/local
.cache/doom-scratch/doom-src/linuxdoom-1.10/doom-headless \
  -headless -iwad .cache/doom-scratch/doom-wad/share/doom/doom1.wad \
  -demo DEMO1 --max-tics 35 -frames out/local/frames.jsonl \
  -state-hashes out/local/state-hashes.jsonl
```

This is a real headless engine replay and deterministic research harness.
After the first build, double-click `Run-Engine-Replay.cmd` to repeat it.
It is not interactive browser gameplay or a local blockchain deployment.
The fetched engine and shareware WAD stay ignored and are never published.

## Next contribution

Build a DoomSol adapter against the signed-input interface, and evaluate it first
against a real local engine. The mock is useful for interface checks only.
On-chain execution additionally needs the SBF toolchain, DCG dependencies, a
validator or testnet deployment, and your own session/keys. Upstream's Mac/Tokyo
launchers assume private infrastructure and cannot be used unchanged.

## Windows fixes

The relay startup uses `pathToFileURL` for Windows paths and paths with spaces.
Two relay tests use `fileURLToPath` rather than URL pathnames.
Verified locally: 162 Node tests passed, one skipped; the real WSL engine
completed a 35-tick DEMO1 replay with frame and state-hash outputs.
Upstream licenses and attribution are retained. DoomSol remains a separate project.
