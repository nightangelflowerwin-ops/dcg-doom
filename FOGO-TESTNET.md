# Fogo testnet preparation

This work is separate from the public browser game. It prepares a DCG/SBF
build in Ubuntu WSL. A successful build alone does not deploy a program or
establish playable on-chain Doom.

## Build prerequisites

Use Ubuntu WSL with Git, curl, tar, bzip2, build-essential, pkg-config, libssl-dev
and Python 3.12 or newer. Install missing Ubuntu packages with:

```sh
sudo apt update
sudo apt install -y build-essential git curl bzip2 pkg-config libssl-dev python3
```

Use a clean clone of this fork's `windows-local` branch on the Linux filesystem
for faster builds. Keep at least several GB free for Rust, CLI, platform tools
and Cargo dependencies; the full SBF build requirement is not yet benchmarked.

```sh
git clone --branch windows-local https://github.com/nightangelflowerwin-ops/dcg-doom.git doomsol-dcg
cd doomsol-dcg
sh scripts/setup-dcg-wsl.sh
sh scripts/build-dcg-wsl.sh
```

Setup installs isolated Rust, Agave/Solana CLI 2.3.9, and uv under ignored
`.deps/wsl-tools`. The SBF compiler uses upstream's platform-tools v1.51.
Neither script creates keys or sends transactions. The build requires a clean
source checkout. Downloads and initial compilation can take substantial time.
The output is `out/sbf/doom_dcg.so` with a SHA-256 file.

If using an existing isolated tools directory, export `DOOM_TOOLS_DIR` before
both scripts. Temporary directories under `/tmp` may disappear after restart.

## Prepare keys after the build

With the isolated tools in PATH and uv installed, run:

```sh
uv run python stunts/doom-dcg/lanes_testnet.py --run-dir out/runs/my-testnet prepare --lanes 3
```

This creates dedicated local payer, authority, program and render-lane keys
under ignored `out/chain/`. It refuses to overwrite existing keys/config.
Only public addresses are printed. Do not share private JSON key files.

The default RPC is `https://testnet.fogo.io`. `DOOM_TESTNET_RPC` can select a
different RPC, but funding/deployment checks its genesis hash against the
expected Fogo testnet before invoking the CLI. No mainnet deployment is intended.

## Remaining prerequisites for a working session

1. Generate the exact RI2 image and packed shareware resource expected by the
   program's pinned resource commitment. `pack-dcg-resource.py` validates existing
   inputs; it does not generate the RI2 input on its own.
2. Establish a sealed resource-source account readable by DCG on the target
   network. The upstream default source key is a local fixture, not a key we own.
   Fresh testnet source-account bootstrapping needs verification before deployment.
3. Obtain native testnet FOGO from https://faucet.fogo.io/ for the dedicated
   addresses. The existing `fund` command transfers from `DOOM_FUNDER_KEY`; it
   does not request faucet tokens. Its upstream amounts are not a measured cost
   estimate for this installation.
4. Deploy the qualified image, provision the game state and render lanes, then
   connect the real relay/player page and verify input-linked transactions.

Provisioning no longer needs the private `baseline-metrics.json`. Without
`DOOM_INIT_METRICS`, it uses the declared CU ceiling and one initialization phase
per transaction, which is conservative and still requires live validation.
Optional measurement files must match phase count and CU bounds.

`provision --resource <packed-resource> --plan-only` constructs a plan without
submitting transactions. The resource must match the pinned length and root.
This is an offline planning aid, not a full deployment preflight.

Official references: https://docs.fogo.io/rpcs.html and
https://docs.fogo.io/user-guides/getting-testnet-tokens.html.
