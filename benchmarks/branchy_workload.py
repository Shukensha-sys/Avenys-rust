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
samples = []
trace = ""
i = 0
total = 0

while i < 3000:
    j = 0
    local = 0

    while j < 32:
        mix = (i * 3 + j * 7) % 11
        if mix % 2 == 0:
            local += mix + i
        if mix % 3 == 0:
            local += j
        if mix % 5 == 0:
            local -= 1
        j += 1

    samples.append(local)
    total += local

    if i % 250 == 0:
        trace = trace + "node".replace("o", "0")

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

print(f"total {total}")
print(f"sum_check {sum(samples)}")
print(f"items {len(samples)}")
print(f"trace_len {len(trace)}")
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
