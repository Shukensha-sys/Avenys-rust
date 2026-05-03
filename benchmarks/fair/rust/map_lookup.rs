use std::collections::HashMap;

fn main() {
    let mut stats: HashMap<&'static str, i64> = HashMap::new();
    stats.insert("alpha", 11);
    stats.insert("beta", 22);
    stats.insert("gamma", 33);
    stats.insert("delta", 44);

    let mut i: i64 = 0;
    let mut total: i64 = 0;

    while i < 500_000 {
        total += *stats.get("alpha").unwrap_or(&0);
        total += *stats.get("beta").unwrap_or(&0);
        total += *stats.get("gamma").unwrap_or(&0);
        total += *stats.get("delta").unwrap_or(&0);
        i += 1;
    }

    println!("{}", total);
}
