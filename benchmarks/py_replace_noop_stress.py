import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    text = "seed"
    i = 0
    
    while i < 20000:
        text = text.replace("seed", "node")
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"text {text}")
    print(f"length {len(text)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"cpu_cycles_est {int(cpu_ms * 3500000)}")
    print(f"process_ram {mem} B")

measure()
