fn main() {
    let mut i: i64 = 0;
    let mut acc: i64 = 0;

    while i < 200_000 {
        let parts: Vec<&str> = "alpha--beta--gamma--delta".split("--").collect();
        let joined = parts.join("|");
        acc += joined.len() as i64;
        i += 1;
    }

    println!("{}", acc);
}
