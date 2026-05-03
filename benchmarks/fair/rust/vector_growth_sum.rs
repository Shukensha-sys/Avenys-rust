fn main() {
    let mut values: Vec<i64> = Vec::new();
    let mut i: i64 = 0;

    while i < 250_000 {
        values.push(i);
        i += 1;
    }

    let mut idx: usize = 0;
    let mut total: i64 = 0;
    let n = values.len();
    while idx < n {
        total += values[idx];
        idx += 1;
    }

    println!("{}", total);
}
