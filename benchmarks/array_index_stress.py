import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

xs = [3, 5, 8, 13, 21, 34, 55, 89]
i = 0
total = 0

while i < 30000:
    total += xs[0]
    total += xs[1]
    total += xs[2]
    total += xs[3]
    total += xs[4]
    total += xs[5]
    total += xs[6]
    total += xs[7]
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
