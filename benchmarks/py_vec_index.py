import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    data = []
    i = 0
    while i < 10000:
        data.append(i)
        i += 1
    
    val = data[5000]
    last = data[9999]
    first = data[0]
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"val {val}")
    print(f"last {last}")
    print(f"first {first}")
    print(f"len {len(data)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"process_ram {mem} B")

measure()
