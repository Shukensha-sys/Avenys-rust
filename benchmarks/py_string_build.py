import time
import resource
import sys

def measure():
    start = time.perf_counter()
    
    limit = 20000
    i = 0
    out = "seed"
    
    while i < limit:
        out = out + "-x"
        i += 1
    
    elapsed = (time.perf_counter() - start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"length {len(out)}")
    print(f"elapsed_ms {elapsed:.3f}")
    print(f"process_ram {mem} B")

measure()
