#!/usr/bin/env bash
set -euo pipefail

# Regression test: MIR backend must NOT silently drop module-level `set`/`let`
# bindings. Previously the construction was dropped and struct field reads folded
# to 0, so a top-level `set p = (P x: 5, y: 3)` printed the WRONG output "0,0"
# with no error. Scalars failed loudly with `undefined value '@n'`.
# See fix in compiler/mir/lower/mod.rs (top-level bindings -> main prologue).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${TMPDIR:-/tmp}/mire_struct_literal_top_level"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

MIRE_BIN="${MIRE_BIN:-$ROOT_DIR/target/release/mire}"
if [[ ! -x "$MIRE_BIN" ]]; then
  echo "Building compiler binary first..."
  (cd "$ROOT_DIR" && cargo build --release --bin mire >/dev/null)
fi

HELPERS='
fn digit_char: (d :i64) :str {
  if d == 0 { return "0" }
  if d == 1 { return "1" }
  if d == 2 { return "2" }
  if d == 3 { return "3" }
  if d == 4 { return "4" }
  if d == 5 { return "5" }
  if d == 6 { return "6" }
  if d == 7 { return "7" }
  if d == 8 { return "8" }
  if d == 9 { return "9" }
  return "?"
}
fn i64_to_str: (n :i64) :str {
  if n == 0 { return "0" }
  set neg = false :bool mut
  set v = n :i64 mut
  if v < 0 {
    set neg = true
    set v = 0 - v
  }
  set buf = "" :str mut
  while v > 0 {
    set d = v % 10
    set buf = digit_char(d) + buf
    set v = v / 10
  }
  if neg { set buf = "-" + buf }
  return buf
}
'

fail() { echo "FAIL: $1"; exit 1; }

# Case 1: top-level struct literal (the reported silent 0,0 bug)
cat > "$WORK_DIR/lit.mire" <<EOF
struct P { x :i64, y :i64 }
$HELPERS
set p = (P x: 5, y: 3)
pub fn main: () {
  dasu(i64_to_str(p.x))
  dasu(",")
  dasu(i64_to_str(p.y))
}
EOF
"$MIRE_BIN" build "$WORK_DIR/lit.mire" -o "$WORK_DIR/lit.out" >/dev/null || fail "lit build failed"
out="$(("$WORK_DIR/lit.out") | tr -d '\n')"
[[ "$out" == "5,3" ]] || fail "lit expected 5,3 got [$out]"

# Case 2: top-level struct literal from variables
cat > "$WORK_DIR/var.mire" <<EOF
struct P { x :i64, y :i64 }
$HELPERS
set a = 5 :i64
set b = 3 :i64
set p = (P x: a, y: b)
pub fn main: () {
  dasu(i64_to_str(p.x))
  dasu(",")
  dasu(i64_to_str(p.y))
}
EOF
"$MIRE_BIN" build "$WORK_DIR/var.mire" -o "$WORK_DIR/var.out" >/dev/null || fail "var build failed"
out="$(("$WORK_DIR/var.out") | tr -d '\n')"
[[ "$out" == "5,3" ]] || fail "var expected 5,3 got [$out]"

# Case 3: top-level scalar binding must not be dropped (loud link error before fix)
cat > "$WORK_DIR/scalar.mire" <<EOF
$HELPERS
set n = 5 :i64
pub fn main: () {
  dasu(i64_to_str(n))
}
EOF
"$MIRE_BIN" build "$WORK_DIR/scalar.mire" -o "$WORK_DIR/scalar.out" >/dev/null || fail "scalar build failed (top-level set dropped?)"
out="$(("$WORK_DIR/scalar.out") | tr -d '\n')"
[[ "$out" == "5" ]] || fail "scalar expected 5 got [$out]"

echo "PASS: top-level struct literals and bindings are lowered correctly"
