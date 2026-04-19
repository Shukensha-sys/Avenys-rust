import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    xs = []
    i = 0
    
    while i < 15000:
        xs.append(i * 3)
        i += 1
    
    total = sum(xs)
    first = xs[0]
    mid = xs[7500]
    last = xs[14999]
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"total {total}")
    print(f"items {len(xs)}")
    print(f"first {first}")
    print(f"mid {mid}")
    print(f"last {last}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cpu_ms * 3500000)}")
    print(f"process_ram {mem} B")

measure()
