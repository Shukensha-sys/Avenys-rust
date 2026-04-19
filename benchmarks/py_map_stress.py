import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    stats = {}
    i = 0
    
    while i < 12000:
        if i % 4 == 0:
            key = "alpha"
            current = stats.get(key, 0)
            stats[key] = current + i
        if i % 4 == 1:
            key = "beta"
            current = stats.get(key, 0)
            stats[key] = current + i
        if i % 4 == 2:
            key = "gamma"
            current = stats.get(key, 0)
            stats[key] = current + i
        if i % 4 == 3:
            key = "delta"
            current = stats.get(key, 0)
            stats[key] = current + i
        i += 1
    
    total = stats.get("alpha", 0) + stats.get("beta", 0) + stats.get("gamma", 0) + stats.get("delta", 0)
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"alpha {stats.get('alpha', 0)}")
    print(f"beta {stats.get('beta', 0)}")
    print(f"gamma {stats.get('gamma', 0)}")
    print(f"delta {stats.get('delta', 0)}")
    print(f"total {total}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cpu_ms * 3500000)}")
    print(f"process_ram {mem} B")

measure()
