import time
import resource

def measure():
    wall = time.perf_counter()
    
    total = 0
    i = 0
    while i < 100:
        j = 0
        while j < 100:
            val = i * 100 + j
            total += val
            j += 1
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    
    print(f"total {total}")
    print(f"wall_ms {wall_ms:.3f}")

measure()
