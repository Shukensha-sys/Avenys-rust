#!/usr/bin/env bash
# CI guard: keep SYNTAX.md's version line in sync with Cargo.toml, and keep the
# documented example count equal to the number of ```mire fenced blocks.
#
# Fails (non-zero) if SYNTAX.md:3 does not match the Cargo.toml package version,
# or if its "N examples" count diverges from the actual fenced-block count.
#
# Run from the avenys/ repo root (or anywhere — paths are resolved relative to
# this script's location).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYNTAX="$ROOT/SYNTAX.md"
CARGO="$ROOT/Cargo.toml"

[ -f "$SYNTAX" ] || { echo "SYNTAX.md not found at $SYNTAX"; exit 1; }
[ -f "$CARGO" ] || { echo "Cargo.toml not found at $CARGO"; exit 1; }

version="$(grep -m1 '^version' "$CARGO" | sed -E 's/version[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
[ -n "$version" ] || { echo "could not parse version from Cargo.toml"; exit 1; }

line3="$(sed -n '3p' "$SYNTAX")"

if ! printf '%s' "$line3" | grep -q "Version: \*\*${version}\*\*"; then
  echo "SYNTAX.md version mismatch:"
  echo "  SYNTAX.md:3 -> $line3"
  echo "  Cargo.toml  -> $version"
  echo "  Update SYNTAX.md line 3 to: Version: **${version}**"
  exit 1
fi

tick=$'\140'
pattern="${tick}${tick}${tick}mire"
actual_examples="$(grep -c "$pattern" "$SYNTAX")"
if ! printf '%s' "$line3" | grep -q "${actual_examples} examples"; then
  echo "SYNTAX.md example count mismatch:"
  echo "  SYNTAX.md:3 claims -> $line3"
  echo "  actual mire-fenced blocks -> $actual_examples"
  echo "  Update SYNTAX.md line 3 to: Version: **${version}** · ${actual_examples} examples"
  exit 1
fi

echo "OK: SYNTAX.md in sync (version ${version}, ${actual_examples} examples)"
