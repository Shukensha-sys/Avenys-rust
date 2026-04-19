import time
import resource
import sys

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    samples = []
    trace = ""
    i = 0
    total = 0
    
    while i < 3000:
        j = 0
        local = 0
        
        while j < 32:
            mix = (i * 3 + j * 7) % 11
            if mix % 2 == 0:
                local += mix + i
            if mix % 3 == 0:
                local += j
            if mix % 5 == 0:
                local -= 1
            j += 1
        
        samples.append(local)
        total += local
        
        if i % 250 == 0:
            chunk = "node".replace("o", "0")
            trace = trace + chunk
        
        i += 1
    
    summed = sum(samples)
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    cycles = cpu_ms * 3_500_000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"total {total}")
    print(f"sum_check {summed}")
    print(f"items {len(samples)}")
    print(f"trace_len {len(trace)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cycles)}")
    print(f"process_ram {mem} B")

measure()
