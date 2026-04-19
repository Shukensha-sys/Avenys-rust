# List slice benchmark in Python
import time

start = time.time()

xs = list(range(10000))

first = xs[0]
last = xs[9999]

sliced = xs[100:200]

elapsed = (time.time() - start) * 1000

print(f"first {first}")
print(f"last {last}")
print(f"sliced_len {len(sliced)}")
print(f"wall_ms {elapsed:.3f}")
