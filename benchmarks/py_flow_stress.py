def weight(x, y):
    base = x * 17 + y * 23
    delta = base // 2 if base % 2 == 0 else base * 3 - 1
    return delta % 997

def main():
    outer = 0
    total = 0
    checksum = 0
    
    while outer < 18000:
        for inner in range(64):
            if inner == 7:
                continue
            
            piece = weight(outer, inner)
            total += piece
            
            if piece % 11 == 0:
                checksum += piece // 11
            
            if inner == 61 and outer % 97 == 0:
                break
        
        outer += 1
    
    tail = 0
    while True:
        tail += 1
        checksum += tail
        if tail == 128:
            break
    
    print(f"total {total}")
    print(f"checksum {checksum}")
    print(f"tag_len {len('avenys-flow-stress')}")

main()
