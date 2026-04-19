import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

stats = {"alpha": 11, "beta": 22, "gamma": 33, "delta": 44}
i = 0
total = 0

while i < 40000:
    total += stats.get("alpha", 0)
    total += stats.get("beta", 0)
    total += stats.get("gamma", 0)
    total += stats.get("delta", 0)
    i += 1

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"total {total}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
