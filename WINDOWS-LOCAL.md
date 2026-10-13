# Run dcg-doom locally on Windows

Follow this guide to reproduce the setup verified on October 13, 2026.
Use the **windows-local** branch. No GitHub login, wallet, paid hosting,
dedicated GPU or access to CrocSwap's private server is required.

## What this setup provides

| Mode | What runs | Limits |
| --- | --- | --- |
| Windows sandbox | Browser page, signed-input interface, Node relay, synthetic frame decoding | Mock frames, not the real Doom engine |
| WSL engine replay | Actual patched Doom engine, built-in DEMO1 replay, frame and state hashes | Headless, not interactive browser gameplay or blockchain execution |

These modes are separate. Installing both does not connect the engine to the
browser. A real-engine browser adapter is future integration work.

## Technical requirements

| Requirement | Details |
| --- | --- |
| Windows | Windows 11 recommended; Microsoft's WSL installation commands also support Windows 10 version 2004, build 19041 or later |
| Architecture | Tested on x64; other architectures unverified |
| Node.js | Current Windows LTS recommended; upstream requires 20 or newer; sandbox only |
| Git for Windows | Required for the clone instructions below |
| PowerShell | Windows PowerShell 5.1 or PowerShell 7 |
| Browser | Modern browser with Web Crypto support; alternate browsers have not been verified here |
| Engine build | WSL 2 Ubuntu with build-essential, Git, curl and ca-certificates |
| Permissions | Administrator access for initial WSL installation; ordinary runs need no elevation |
| Network | Initial installations, clone, Linux packages, source and shareware WAD downloads |
| Ports | Sandbox requires free local TCP ports 18080 and 18787 |

For the combined setup, plan for a 64-bit CPU, 8 GB RAM and 10 GB free disk for
WSL, Ubuntu and build files. These are planning recommendations, not measured
minimums. No dedicated GPU is required. WSL 2 requires firmware virtualization.
Windows Python, Rust, Docker, SBF tools and wallet extensions are not required.
After the initial installation/build, local runs need no blockchain access.
Rebuilding may contact the network because the build fetches pinned source.

## Step 1: Install Windows tools

Install [Git for Windows](https://git-scm.com/install/windows), including Git in
PATH, and the Windows installer for the current [Node.js LTS](https://nodejs.org/en/download).
Close and reopen PowerShell, then verify:

```powershell
git --version
node --version
```

No `npm install` is needed: the local sandbox uses Node's built-in modules.

## Step 2: Clone this fork

Run in normal Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\Documents\Projects" | Out-Null
Set-Location "$env:USERPROFILE\Documents\Projects"
git -c core.autocrlf=false clone --branch windows-local https://github.com/nightangelflowerwin-ops/dcg-doom.git
Set-Location dcg-doom
git config core.autocrlf false
git branch --show-current
```

Expect `windows-local`. LF line endings are essential for Linux scripts and
patches. Prefer a Git clone over a ZIP download and a folder outside cloud sync.
If the destination already exists, choose another folder or use your existing
checkout. Do not overwrite your work.

## Step 3: Launch the browser sandbox

In File Explorer, double-click `Start-Windows-Local.cmd` in the cloned folder.
Or, in Windows PowerShell at the repository root:

```powershell
.\Start-Windows-Local.cmd
```

Keep the launcher window open. If the browser opens before startup completes,
refresh after the URL appears in the terminal. Open:

http://127.0.0.1:18080/doom-play/?relayer=http://127.0.0.1:18787

Set the page's relay field to `http://127.0.0.1:18787`, then click **JOIN**.
Use the on-page movement/fire buttons to exercise inputs. Frames are synthetic,
so this is an interface sandbox, not playable Doom. Upstream testnet labels may
appear on the page; the actual local relay reports `mode: mock`.

In another Windows PowerShell window, verify:

```powershell
Invoke-RestMethod http://127.0.0.1:18787/healthz
```

Expect `ok: True` and `mode: mock`. Both listeners are bound to this computer's
loopback address. Only `web/` is served; keys, engine files and run outputs are
outside the web root. Stop with Ctrl+C in the launcher window; answer Y if asked
to terminate the batch job. Closing only the browser does not stop the servers.

## Step 4: Install WSL Ubuntu for the real engine

Check first in PowerShell:

```powershell
wsl --list --verbose
```

Skip installation if you already have working Ubuntu. Otherwise open **PowerShell
as Administrator**, run the following, and restart if prompted:

```powershell
wsl --install -d Ubuntu
```

Open Ubuntu from Start and create your Linux username/password. Password entry
normally shows no characters. See [Microsoft's WSL installation guide](https://learn.microsoft.com/en-us/windows/wsl/install).
The launchers use your default WSL distribution. If needed, set Ubuntu as default:

```powershell
wsl --set-default Ubuntu
```

Use the exact distribution name from the list, such as `Ubuntu-24.04` if applicable.
Check VERSION is 2; if necessary use `wsl --set-version Ubuntu 2`, substituting
your actual distribution name.

## Step 5: Install Linux build tools

Run these **inside Ubuntu**, not Windows PowerShell:

```sh
sudo apt update
sudo apt install -y build-essential git curl ca-certificates
gcc --version
make --version
git --version
```

## Step 6: Build the real engine

Open normal Windows PowerShell in the cloned repository and enter `wsl`.
Inside Ubuntu, check you are at the repository root:

```sh
pwd
ls stunts/doom-host/build.sh
```

If the file is missing, navigate to the clone. For example,
`C:\Users\YourName\Documents\Projects\dcg-doom` maps to
`/mnt/c/Users/YourName/Documents/Projects/dcg-doom`. Quote paths with spaces.
Then run:

```sh
DOOM_SCRATCH="$PWD/.cache/doom-scratch" sh stunts/doom-host/build.sh
```

This fetches pinned id Software engine source, applies the patches, downloads
the shareware WAD from the configured NetBSD mirror, verifies its size/SHA-256,
and compiles the native executable. Allow several minutes depending on the
computer, connection and filesystem. Success ends with a path ending in
`linuxdoom-1.10/doom-headless`. Compiler/patch whitespace warnings occurred here;
an explicit error or nonzero exit means the build did not complete.

Fetched assets stay under ignored `.cache/`. Do not commit them or disable
checksum verification. Building through `/mnt/c` worked here but can be slower
than using the Linux filesystem.

## Step 7: Run and verify the replay

Type `exit` to return to Windows. Double-click `Run-Engine-Replay.cmd`, or run
from Windows PowerShell at the repository root:

```powershell
.\Run-Engine-Replay.cmd
```

Expect `doom-headless: tics=35` and `Replay completed`. No game window appears
because this is headless replay. It produces:

- `out/local/frames.jsonl`: 315 records, including 35 whole-frame hashes and eight strip hashes per frame.
- `out/local/state-hashes.jsonl`: 35 state-hash records.

These are hashes/metadata, not a video or raw frame image export. Each replay
replaces these files. Copy them first if you want to retain earlier results.
Verify counts in Windows PowerShell:

```powershell
(Get-Content .\out\local\frames.jsonl | Measure-Object -Line).Lines
(Get-Content .\out\local\state-hashes.jsonl | Measure-Object -Line).Lines
```

Expect 315 and 35. This proves local engine execution, not level completion,
interactive control or on-chain execution.

## Step 8: Optional Windows tests

Run at the repository root in Windows PowerShell:

```powershell
node --test stunts/doom-relayer/test/test_relayer.mjs stunts/doom-relayer/test/test_public_mode.mjs web/doom-play/test/test_input.mjs web/doom-play/test/test_inputlog.mjs web/doom-play/test/test_page_offline.mjs web/doom-play/test/test_palette.mjs web/doom-play/test/test_push.mjs web/doom-play/test/test_strip.mjs
```

Verified result: 162 passes, zero failures, one skipped. This covers relay/page
modules, not the complete Rust/Python suite or a live browser test.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Missing `git` or `node` | Reopen PowerShell; verify installation/PATH |
| Missing launchers | Use `windows-local`, not upstream `main` |
| `EADDRINUSE` | Stop your previous launcher; identify port 18080/18787 owners before stopping other processes |
| Browser cannot connect | Keep launcher running, refresh after startup, check `/healthz` |
| JOIN uses another relay | Correct the relay field; the page can remember earlier values |
| Mock frames do not look like Doom | Expected for this sandbox |
| WSL unavailable | Follow Microsoft's installation guide and restart if prompted |
| Wrong Linux distribution | Check/set the default Ubuntu distribution |
| Missing compiler/tools | Repeat step 5 |
| `set: Illegal option` or `^M` | CRLF files: create a fresh clone with the exact `core.autocrlf=false` command above |
| Replay executable missing | Finish step 6 using the exact scratch directory |
| Download/checksum failure | Check the connection/error; keep checksum verification enabled |
| Organization blocks PowerShell | CMD launchers use a process-scoped execution-policy override, without changing machine policy; organization policy can still block it |

## Tested environment, sharing and updates

Tested on Windows 11 Pro x64; Node.js 26.7.0; Ubuntu 24.04.1 LTS; GCC 13.3.0;
GNU Make 4.3; Linux Git 2.43.0. Prefer a supported Node LTS for new installations.
A fresh installation on a second computer has not been verified. Hardware
minimums and alternate browsers/architectures have not been benchmarked.

Share this guide's public GitHub URL. A localhost URL only works on the computer
running the server. Each person clones and runs their own copy, without tunneling
or public hosting. Preserve upstream attribution in `LICENSE` and `NOTICE.md`.
DoomSol remains a separate project.

To update a checkout with no uncommitted changes:

```powershell
git switch windows-local
git pull --ff-only origin windows-local
```

Rebuild after engine patch changes. Record `git rev-parse HEAD` and tool versions
with reproducibility reports. Keep ignored WADs, keys and local outputs out of Git.
