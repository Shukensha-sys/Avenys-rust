import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

flags = {}
i = 0

while i < 20000:
    flags[1] = i % 2 == 0
    flags[2] = i % 3 == 0
    flags[3] = i % 5 == 0
    flags[4] = i % 7 == 0
    i += 1

score = 0
if flags.get(1, False):
    score += 1
if flags.get(2, False):
    score += 10
if flags.get(3, False):
    score += 100
if flags.get(4, False):
    score += 1000

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"score {score}")
print(f"flags {flags}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
