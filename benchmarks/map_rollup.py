counts = {}
sums = {}

for i in range(10000):
    bucket = "cold"
    if i % 4 == 0:
        bucket = "warm"
    if i % 9 == 0:
        bucket = "hot"

    counts[bucket] = counts.get(bucket, 0) + 1
    sums[bucket] = sums.get(bucket, 0) + i

print(f"counts {counts}")
print(f"sums {sums}")
