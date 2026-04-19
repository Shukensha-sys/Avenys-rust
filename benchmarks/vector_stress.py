import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

xs = []
for i in range(15000):
    xs.append(i * 3)

total = sum(xs)
wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"total {total}")
print(f"items {len(xs)}")
print(f"first {xs[0]}")
print(f"mid {xs[7500]}")
print(f"last {xs[14999]}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
