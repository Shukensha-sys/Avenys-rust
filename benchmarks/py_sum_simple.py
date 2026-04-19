import time
import resource

def measure():
    wall = time.perf_counter()
    
    total = 0
    i = 0
    while i < 1000000:
        total += i
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    
    print(f"total {total}")
    print(f"wall_ms {wall_ms:.3f}")

measure()
