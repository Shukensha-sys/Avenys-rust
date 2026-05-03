#!/usr/bin/env bash
set -euo pipefail

REPEAT="${REPEAT:-11}"
WARMUP="${WARMUP:-3}"
RESULTS="benchmarks/fair/RESULTS.md"

WORKLOADS=(sum_loop map_lookup vector_growth_sum)

median_us() {
  local -a vals=("$@")
  printf '%s\n' "${vals[@]}" | sort -n | awk 'NR==int((NF+1)/2){print $1}' NF="${#vals[@]}"
}

run_us() {
  local bin="$1"
  local start end
  start=$(date +%s%N)
  "$bin" >/tmp/mire_bench_out.txt
  end=$(date +%s%N)
  echo $(((end - start) / 1000))
}

format_ms3() {
  local us="$1"
  awk -v u="$us" 'BEGIN { printf "%.3f", u/1000.0 }'
}

mkdir -p benchmarks/fair/build/mire benchmarks/fair/build/rust

echo "[1/4] Building Mire compiler (release)..."
cargo build --release >/tmp/mire_build_release.log 2>&1

echo "[2/4] Compiling workload binaries..."
for w in "${WORKLOADS[@]}"; do
  ./target/release/mire build "benchmarks/fair/mire/${w}.mire" --output "benchmarks/fair/build/mire/${w}" >/tmp/mire_build_${w}.log 2>&1
  rustc "benchmarks/fair/rust/${w}.rs" -O -C target-cpu=native -C codegen-units=1 -C lto=fat -o "benchmarks/fair/build/rust/${w}"
done

echo "[3/4] Output parity check..."
for w in "${WORKLOADS[@]}"; do
  mire_out=$("benchmarks/fair/build/mire/${w}" | tr -d '\r' | tail -n 1)
  rust_out=$("benchmarks/fair/build/rust/${w}" | tr -d '\r' | tail -n 1)
  if [[ "$mire_out" != "$rust_out" ]]; then
    echo "Output mismatch in ${w}: mire='${mire_out}' rust='${rust_out}'"
    exit 1
  fi
done

echo "[4/4] Running fair benchmark (warmup=${WARMUP}, repeat=${REPEAT})..."

{
  echo "# Fair Benchmark: Mire vs Rust"
  echo
  echo "- Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  echo "- Warmup: ${WARMUP}"
  echo "- Repeat: ${REPEAT}"
  echo "- Timer: wall-clock nanoseconds via date +%s%N (reported as median ms)"
  echo "- Mire build: ./target/release/mire build (release defaults)"
  echo "- Rust build flags: -O -C target-cpu=native -C codegen-units=1 -C lto=fat"
  echo
  echo "| Workload | Mire median (ms) | Rust median (ms) | Rust/Mire |"
  echo "|---|---:|---:|---:|"

  for w in "${WORKLOADS[@]}"; do
    for _ in $(seq 1 "$WARMUP"); do
      "benchmarks/fair/build/mire/${w}" >/dev/null
      "benchmarks/fair/build/rust/${w}" >/dev/null
    done

    mire_runs=()
    rust_runs=()

    for _ in $(seq 1 "$REPEAT"); do
      mire_runs+=("$(run_us "benchmarks/fair/build/mire/${w}")")
      rust_runs+=("$(run_us "benchmarks/fair/build/rust/${w}")")
    done

    mire_med_us=$(median_us "${mire_runs[@]}")
    rust_med_us=$(median_us "${rust_runs[@]}")
    mire_ms=$(format_ms3 "$mire_med_us")
    rust_ms=$(format_ms3 "$rust_med_us")
    ratio=$(awk -v r="$rust_med_us" -v m="$mire_med_us" 'BEGIN { if (m==0) print "n/a"; else printf "%.3f", r/m }')

    echo "| ${w} | ${mire_ms} | ${rust_ms} | ${ratio}x |"
  done
} > "$RESULTS"

echo "Done. Results: $RESULTS"
cat "$RESULTS"
