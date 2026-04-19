import os
import time


start = time.perf_counter()
limit = 1_000_000
i = 0
acc = 0

while i < limit:
    acc += i
    i += 1

elapsed_ms = (time.perf_counter() - start) * 1000.0

print(f"result {acc}")
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
