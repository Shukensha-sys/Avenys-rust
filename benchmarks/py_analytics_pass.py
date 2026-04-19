import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    counts = {}
    sums = {}
    report = ""
    i = 0
    
    while i < 20000:
        bucket = "gamma"
        if i % 7 == 0:
            bucket = "alpha"
        if bucket == "gamma" and i % 5 == 0:
            bucket = "beta"
        
        current_count = counts.get(bucket, 0)
        next_count = current_count + 1
        counts[bucket] = next_count
        
        current_sum = sums.get(bucket, 0)
        next_sum = current_sum + i
        sums[bucket] = next_sum
        
        if i % 1000 == 0:
            report = report + bucket.replace("a", "A")
        
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    cycles = cpu_ms * 3_500_000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"counts {counts}")
    print(f"sums {sums}")
    print(f"report_len {len(report)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cycles)}")
    print(f"process_ram {mem} B")

measure()
