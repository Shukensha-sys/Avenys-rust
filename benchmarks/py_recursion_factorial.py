# Recursion factorial benchmark in Python
import time

def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

start = time.time()
result = factorial(13)  # 13! = 6227020800
elapsed = (time.time() - start) * 1000

print(f"result {result}")
print(f"wall_ms {elapsed:.3f}")
