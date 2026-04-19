# Higher-order filter benchmark in Python
import time

start = time.time()

nums = list(range(10000))

def is_even(n):
    return n % 2 == 0

filtered = []
for n in nums:
    if is_even(n):
        filtered.append(n)

total = sum(filtered)

elapsed = (time.time() - start) * 1000

print(f"total {total}")
print(f"items {len(filtered)}")
print(f"wall_ms {elapsed:.3f}")
