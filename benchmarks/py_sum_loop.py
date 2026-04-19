import time
import sys

def measure():
    start = time.perf_counter()
    
    limit = 1000000
    i = 0
    acc = 0
    
    while i < limit:
        acc += i
        i += 1
    
    elapsed = (time.perf_counter() - start) * 1000
    import resource
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"result {acc}")
    print(f"elapsed_ms {elapsed:.3f}")
    print(f"process_ram {mem} B")

measure()
