use std::time::Instant;

fn main() {
    println!("=== Mire vs Rust - Fair Comparison (No Optimization) ===");
    println!();
    
    benchmark_sum_loop();
    benchmark_map_heavy();
    benchmark_vector_growth();
    benchmark_nested_compute();
    benchmark_string_build();
}

fn benchmark_sum_loop() {
    println!("[1] Sum Loop (10M iterations) - No optimization");
    
    let start = Instant::now();
    let mut acc = 0i64;
    let limit = 10000000i64;
    let mut i = 0i64;

    while i < limit {
        acc += i;
        i += 1;
    }
    let elapsed = start.elapsed();
    println!("    Rust: {}ms, result: {}", elapsed.as_millis(), acc);
    println!();
}

fn benchmark_map_heavy() {
    println!("[2] Map Operations (100K entries)");
    
    let start = Instant::now();
    use std::collections::HashMap;
    let mut map: HashMap<i64, i64> = HashMap::new();
    let mut i = 0i64;

    while i < 100000 {
        map.insert(i, i * 2);
        i += 1;
    }
    
    i = 0;
    let mut sum = 0i64;
    while i < 100000 {
        if let Some(v) = map.get(&i) {
            sum += v;
        }
        i += 1;
    }
    let elapsed = start.elapsed();
    println!("    Rust: {}ms, sum: {}", elapsed.as_millis(), sum);
    println!();
}

fn benchmark_vector_growth() {
    println!("[3] Vector Growth (50K push + iterate)");
    
    let start = Instant::now();
    let mut vec = Vec::new();
    let mut i = 0i64;

    while i < 50000 {
        vec.push(i);
        i += 1;
    }
    
    let mut sum = 0i64;
    for v in &vec {
        sum += v;
    }
    let elapsed = start.elapsed();
    println!("    Rust: {}ms, sum: {}", elapsed.as_millis(), sum);
    println!();
}

fn benchmark_nested_compute() {
    println!("[4] Nested Loop Compute (500x500)");
    
    let start = Instant::now();
    let mut sum = 0i64;
    let mut i = 0i64;

    while i < 500 {
        let mut j = 0i64;
        while j < 500 {
            sum += i * j;
            j += 1;
        }
        i += 1;
    }
    let elapsed = start.elapsed();
    println!("    Rust: {}ms, sum: {}", elapsed.as_millis(), sum);
    println!();
}

fn benchmark_string_build() {
    println!("[5] String Build (10K concatenations)");
    
    let start = Instant::now();
    let mut result = String::new();
    let mut i = 0i64;

    while i < 10000 {
        result.push_str("item");
        result.push_str(&i.to_string());
        result.push_str(",");
        i += 1;
    }
    let elapsed = start.elapsed();
    println!("    Rust: {}ms, len: {}", elapsed.as_millis(), result.len());
    println!();
}