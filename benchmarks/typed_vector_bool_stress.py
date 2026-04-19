import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

flags = []
i = 0

while i < 20000:
    flags.append(i % 2 == 0)
    i += 1

total = 0
j = 0
while j < len(flags):
    if flags[j]:
        total += 1
    j += 1

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"total {total}")
print(f"items {len(flags)}")
print(f"first {str(flags[0]).lower()}")
print(f"last {str(flags[19999]).lower()}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
