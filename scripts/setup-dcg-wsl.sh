#!/bin/sh
# Installs isolated build tools; submits no transactions and creates no keys.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools=${DOOM_TOOLS_DIR:-$root/.deps/wsl-tools}
mkdir -p "$tools"
export RUSTUP_HOME="$tools/rustup" CARGO_HOME="$tools/cargo"
export PATH="$CARGO_HOME/bin:$tools/solana-release/bin:$tools/uv:$PATH"
if ! command -v cargo >/dev/null 2>&1; then
  curl --fail --location --retry 2 https://sh.rustup.rs -o "$tools/rustup-init.sh"
  sh "$tools/rustup-init.sh" -y --no-modify-path --profile minimal
fi
if ! command -v solana >/dev/null 2>&1; then
  curl --fail --location --retry 2 https://github.com/anza-xyz/agave/releases/download/v2.3.9/solana-release-x86_64-unknown-linux-gnu.tar.bz2 -o "$tools/agave.tar.bz2"
  tar -xjf "$tools/agave.tar.bz2" -C "$tools"
fi
if ! command -v uv >/dev/null 2>&1; then
  curl --fail --location --retry 2 https://astral.sh/uv/install.sh -o "$tools/uv-install.sh"
  UV_INSTALL_DIR="$tools/uv" UV_NO_MODIFY_PATH=1 sh "$tools/uv-install.sh"
fi
cargo --version
solana --version
cargo-build-sbf --version
uv --version
printf 'Tool directory: %s\n' "$tools"
