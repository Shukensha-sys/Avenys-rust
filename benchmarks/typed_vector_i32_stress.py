import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

xs = []
i = 0

while i < 30000:
    xs.append(i)
    i += 1

total = sum(xs)
wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"total {total}")
print(f"items {len(xs)}")
print(f"first {xs[0]}")
print(f"mid {xs[15000]}")
print(f"last {xs[29999]}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
