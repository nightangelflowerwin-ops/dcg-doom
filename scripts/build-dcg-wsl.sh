#!/bin/sh
# Build only: no funding, keys, deployment, or changes to the browser game.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
tools=${DOOM_TOOLS_DIR:-$root/.deps/wsl-tools}
export RUSTUP_HOME="$tools/rustup" CARGO_HOME="$tools/cargo"
export PATH="$CARGO_HOME/bin:$tools/solana-release/bin:$tools/uv:$PATH"
for tool in cargo cargo-build-sbf uv; do command -v "$tool" >/dev/null || { echo "Missing $tool; run setup-dcg-wsl.sh first" >&2; exit 1; }; done
if [ -n "$(git status --porcelain --untracked-files=all)" ]; then
  echo 'Build requires a clean Git checkout for source provenance.' >&2
  exit 1
fi
export DOOM_SCRATCH="$root/.cache/doom-scratch"
export DOOM_SBF_SOURCE_TREE=$(git rev-parse HEAD:stunts/doom-sbf)
uv sync --locked
uv run pytest tests/test_doom_deployment_portability.py tests/test_doom_lanes_plan.py -q
sh stunts/doom-host/build.sh
mkdir -p out/sbf
cargo-build-sbf --manifest-path stunts/doom-dcg/Cargo.toml --features sbf --sbf-out-dir out/sbf --tools-version v1.51
sha256sum out/sbf/doom_dcg.so > out/sbf/doom_dcg.sha256
echo 'SBF image built. This is not a deployed or qualified game session.'
