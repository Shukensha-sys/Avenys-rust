fn main() {
    let limit: i64 = 3_000_000;
    let mut i: i64 = 0;
    let mut acc: i64 = 0;

    while i < limit {
        acc += i;
        i += 1;
    }

    println!("{}", acc);
}
