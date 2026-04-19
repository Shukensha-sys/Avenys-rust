import shutil
import subprocess
import time


def gpu_snapshot():
    if shutil.which("nvidia-smi") is None:
        return "available=false"
    try:
        out = subprocess.run(
            [
                "nvidia-smi",
                "--query-gpu=name,utilization.gpu,memory.used,memory.total",
                "--format=csv,noheader,nounits",
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=0.2,
        )
        return out.stdout.strip().splitlines()[0]
    except Exception:
        return "available=false"


wall_start = time.perf_counter()
cpu_start = time.process_time()
counts = {}
sums = {}
report = ""
i = 0

while i < 20_000:
    bucket = "gamma"
    if i % 7 == 0:
        bucket = "alpha"
    elif i % 5 == 0:
        bucket = "beta"

    counts[bucket] = counts.get(bucket, 0) + 1
    sums[bucket] = sums.get(bucket, 0) + i

    if i % 1000 == 0:
        report = report + bucket.replace("a", "A")

    i += 1

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0

freq_mhz = 0.0
try:
    with open("/proc/cpuinfo", "r", encoding="utf-8") as fh:
        for line in fh:
            if line.lower().startswith("cpu mhz"):
                freq_mhz = float(line.split(":")[1].strip())
                break
except OSError:
    pass

cycles_est = int((cpu_ms / 1000.0) * freq_mhz * 1_000_000.0)

print(f"counts {counts}")
print(f"sums {sums}")
print(f"report_len {len(report)}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cycles_est}")

try:
    with open("/proc/self/status", "r", encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("VmRSS:"):
                kb = int(line.split()[1])
                print(f"process_ram {kb * 1024} B")
                break
except OSError:
    print("process_ram unavailable")

print(f"gpu {gpu_snapshot()}")
