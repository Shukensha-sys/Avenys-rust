import time
import resource
import sys

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    xs = []
    i = 0
    
    while i < 20000:
        xs.append(i)
        i += 1
    
    total = sum(xs)
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    cycles = cpu_ms * 3_500_000  # estimate
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024  # KB to bytes
    
    print(f"total {total}")
    print(f"items {len(xs)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cycles)}")
    print(f"process_ram {mem} B")

measure()
