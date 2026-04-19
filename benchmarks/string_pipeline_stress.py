out = ""

for _ in range(8000):
    line = " pending-item ".replace("-", "_")
    line = line.upper()
    line = line.strip()
    out += line

print(f"out_len {len(out)}")
