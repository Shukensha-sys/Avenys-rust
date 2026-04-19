# Recursion fibonacci benchmark in Python
import time

def fib(n):
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

start = time.time()
result = fib(20)
elapsed = (time.time() - start) * 1000

print(f"result {result}")
print(f"wall_ms {elapsed:.3f}")
