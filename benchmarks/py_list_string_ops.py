# List string operations benchmark in Python
import time

start = time.time()

xs = []
xs.append("hello")
xs.append("world")
xs.append("test")

first = xs[0]
second = xs[1]
last = xs[2]
l = len(xs)

elapsed = (time.time() - start) * 1000

print(f"first {first}")
print(f"second {second}")
print(f"last {last}")
print(f"len {l}")
print(f"wall_ms {elapsed:.3f}")
