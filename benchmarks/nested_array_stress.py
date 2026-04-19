import os
import resource
import time

wall_start = time.perf_counter()
cpu_start = time.process_time()

matrix = [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12]]
rows = len(matrix)
cols = len(matrix[0])
total = sum(sum(row) for row in matrix)
edge = matrix[2][3]

wall_ms = (time.perf_counter() - wall_start) * 1000.0
cpu_ms = (time.process_time() - cpu_start) * 1000.0
cpu_cycles_est = int(cpu_ms * 1000.0 * (os.cpu_count() or 1))
process_ram = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024

print(f"rows {rows}")
print(f"cols {cols}")
print(f"total {total}")
print(f"edge {edge}")
print(f"wall_ms {wall_ms:.3f}")
print(f"cpu_ms {cpu_ms:.3f}")
print(f"cpu_cycles_est {cpu_cycles_est}")
print(f"process_ram {process_ram} B")
