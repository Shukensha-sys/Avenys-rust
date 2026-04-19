import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

alpha = {"x": 11, "y": 22}
beta = {"x": 33, "y": 44}
gamma = {"x": 55, "y": 66}

outer = {
    "alpha": alpha,
    "beta": beta,
    "gamma": gamma,
}

picked = outer.get("beta", {})
total = (
    outer.get("alpha", {}).get("x", 0)
    + outer.get("alpha", {}).get("y", 0)
    + outer.get("beta", {}).get("x", 0)
    + outer.get("beta", {}).get("y", 0)
    + outer.get("gamma", {}).get("x", 0)
    + outer.get("gamma", {}).get("y", 0)
)
edge = picked.get("y", 0)

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"groups {outer}")
print(f"total {total}")
print(f"edge {edge}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
