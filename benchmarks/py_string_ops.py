import time
import resource

def measure():
    wall = time.perf_counter()
    proc_start = time.process_time()
    
    text = "Hello World"
    result = ""
    
    i = 0
    while i < 10000:
        result = text.upper()
        result = result.lower()
        result = result.replace("world", "mire")
        i += 1
    
    wall_ms = (time.perf_counter() - wall) * 1000
    cpu_ms = (time.process_time() - proc_start) * 1000
    mem = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    
    print(f"result {result}")
    print(f"len {len(result)}")
    print(f"wall_ms {wall_ms:.3f}")
    print(f"cpu_ms {cpu_ms:.3f}")
    print(f"process_ram {mem} B")

measure()
