import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

stats = {}
for i in range(12000):
    if i % 4 == 0:
        key = "alpha"
    elif i % 4 == 1:
        key = "beta"
    elif i % 4 == 2:
        key = "gamma"
    else:
        key = "delta"
    stats[key] = stats.get(key, 0) + i

total = stats.get("alpha", 0) + stats.get("beta", 0) + stats.get("gamma", 0) + stats.get("delta", 0)

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"alpha {stats.get('alpha', 0)}")
print(f"beta {stats.get('beta', 0)}")
print(f"gamma {stats.get('gamma', 0)}")
print(f"delta {stats.get('delta', 0)}")
print(f"total {total}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
