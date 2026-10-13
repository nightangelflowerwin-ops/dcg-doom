#!/bin/sh
# Installs isolated build tools; submits no transactions and creates no keys.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools=${DOOM_TOOLS_DIR:-$root/.deps/wsl-tools}
mkdir -p "$tools"
export RUSTUP_HOME="$tools/rustup" CARGO_HOME="$tools/cargo"
export PATH="$CARGO_HOME/bin:$tools/solana-release/bin:$tools/uv:$PATH"
if [ ! -x "$CARGO_HOME/bin/cargo" ]; then
  curl --fail --location --retry 2 https://sh.rustup.rs -o "$tools/rustup-init.sh"
  sh "$tools/rustup-init.sh" -y --no-modify-path --profile minimal
fi
if [ ! -x "$tools/solana-release/bin/solana" ] || [ ! -x "$tools/solana-release/bin/cargo-build-sbf" ]; then
  curl --fail --location --retry 2 https://github.com/anza-xyz/agave/releases/download/v2.3.9/solana-release-x86_64-unknown-linux-gnu.tar.bz2 -o "$tools/agave.tar.bz2"
  tar -xjf "$tools/agave.tar.bz2" -C "$tools"
fi
if [ ! -x "$tools/uv/uv" ]; then
  curl --fail --location --retry 2 https://astral.sh/uv/install.sh -o "$tools/uv-install.sh"
  UV_INSTALL_DIR="$tools/uv" UV_NO_MODIFY_PATH=1 sh "$tools/uv-install.sh"
fi
# Align Agave's post-processing SDK with the compiler version.
sdk="$tools/sbf-sdk-v1.51"
if [ ! -d "$sdk" ]; then
  cp -R "$tools/solana-release/bin/platform-tools-sdk/sbf" "$sdk"
fi
python3 - "$sdk/scripts/install.sh" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
s = p.read_text()
if 'version=v1.48' in s:
    s = s.replace('version=v1.48', 'version=v1.51')
elif 'version=v1.51' not in s:
    raise SystemExit('Unrecognized SDK platform-tools version')
p.write_text(s)
PY
cargo --version
solana --version
cargo-build-sbf --version
uv --version
printf 'Tool directory: %s\n' "$tools"
