use std::fs;
use std::time::Instant;

fn workload(limit: i64) -> i64 {
    let mut i = 0_i64;
    let mut acc = 0_i64;
    let split = limit / 2;

    while i < limit {
        if i < split {
            acc += i * 3;
        } else {
            acc += i / 3;
        }
        i += 1;
    }

    acc
}

fn process_rss_bytes() -> Option<u64> {
    let status = fs::read_to_string("/proc/self/status").ok()?;
    for line in status.lines() {
        if line.starts_with("VmRSS:") {
            let kb = line.split_whitespace().nth(1)?.parse::<u64>().ok()?;
            return Some(kb * 1024);
        }
    }
    None
}

fn format_bytes(bytes: u64) -> String {
    const KB: f64 = 1024.0;
    const MB: f64 = KB * 1024.0;
    let value = bytes as f64;
    if value >= MB {
        format!("{:.2} MB", value / MB)
    } else if value >= KB {
        format!("{:.2} KB", value / KB)
    } else {
        format!("{bytes} B")
    }
}

fn main() {
    let start = Instant::now();
    let limit = 5_000_000_i64;
    let result = workload(limit);
    let elapsed_ms = start.elapsed().as_secs_f64() * 1000.0;

    println!("result {result}");
    println!("elapsed_ms {:.3}", elapsed_ms);
    if let Some(rss) = process_rss_bytes() {
        println!("process_ram {}", format_bytes(rss));
    }
}
