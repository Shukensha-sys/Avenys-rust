import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

stats = {
    "k00": 1,
    "k01": 2,
    "k02": 3,
    "k03": 4,
    "k04": 5,
    "k05": 6,
    "k06": 7,
    "k07": 8,
    "k08": 9,
    "k09": 10,
    "k10": 11,
    "k11": 12,
    "k12": 13,
    "k13": 14,
    "k14": 15,
    "k15": 16,
}

i = 0
total = 0

while i < 20000:
    total += stats.get("k00", 0)
    total += stats.get("k01", 0)
    total += stats.get("k02", 0)
    total += stats.get("k03", 0)
    total += stats.get("k04", 0)
    total += stats.get("k05", 0)
    total += stats.get("k06", 0)
    total += stats.get("k07", 0)
    total += stats.get("k08", 0)
    total += stats.get("k09", 0)
    total += stats.get("k10", 0)
    total += stats.get("k11", 0)
    total += stats.get("k12", 0)
    total += stats.get("k13", 0)
    total += stats.get("k14", 0)
    total += stats.get("k15", 0)
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
