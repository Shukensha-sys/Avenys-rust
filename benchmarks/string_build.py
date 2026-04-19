import time


start = time.perf_counter()
limit = 20_000
i = 0
out = "seed"

while i < limit:
    out = f"{out}-x"
    i += 1

elapsed_ms = (time.perf_counter() - start) * 1000.0

print(f"length {len(out)}")
print(f"elapsed_ms {elapsed_ms:.3f}")

try:
    with open("/proc/self/status", "r", encoding="utf-8") as fh:
        for line in fh:
            if line.startswith("VmRSS:"):
                kb = int(line.split()[1])
                print(f"process_ram {kb * 1024} B")
                break
except OSError:
    print("process_ram unavailable")
