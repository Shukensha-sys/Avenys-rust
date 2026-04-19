import time
import resource
import sys

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    stats = {}
    stats["alpha"] = 11
    stats["beta"] = 22
    stats["gamma"] = 33
    stats["delta"] = 44
    
    i = 0
    total = 0
    
    while i < 40000:
        total += stats.get("alpha", 0)
        total += stats.get("beta", 0)
        total += stats.get("gamma", 0)
        total += stats.get("delta", 0)
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    cycles = cpu_ms * 3_500_000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"total {total}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cycles)}")
    print(f"process_ram {mem} B")

measure()
