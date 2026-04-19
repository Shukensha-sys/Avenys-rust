queue = []
total = 0
digest = ""

for i in range(12000):
    priority = (i * 7 + 3) % 11
    queue.append(priority)
    total += priority
    if priority % 3 == 0:
        digest += "tAsk".replace("A", "A")

print(f"total {total}")
print(f"items {len(queue)}")
print(f"digest_len {len(digest)}")
