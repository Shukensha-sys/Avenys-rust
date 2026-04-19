import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

left = [2, 4, 6]
right = [3, 5, 7]
groups = {
    "left": left,
    "right": right,
}

picked = groups.get("right", [])
total = (
    groups.get("left", [])[0]
    + groups.get("left", [])[1]
    + groups.get("left", [])[2]
    + picked[0]
    + picked[1]
    + picked[2]
)
edge = picked[2]

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"total {total}")
print(f"edge {edge}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
