import time
import resource

def measure():
    wall = time.perf_counter()
    
    nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    squared = [val * val for val in nums]
    
    total = sum(squared)
    
    wall_ms = (time.perf_counter() - wall) * 1000
    
    print(f"total {total}")
    print(f"wall_ms {wall_ms:.3f}")

measure()
