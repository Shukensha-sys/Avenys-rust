use mire::error::diagnostic::{Diagnostic, DiagnosticCode, Severity, WarningFilter};
use mire::error::format::format_diagnostic;
use mire::lexer::tokenize;
use mire::parser::parse;
use mire::{
    BuildMode, BuildOptions, BuildResult, CacheOverrides, ImportMode, MireError, OptLevel,
    WarningConfig, analyze_program, analyze_program_with_warnings_and_origins,
    compile_file_with_avenys, default_output_dir, find_project_root, load_program_with_metadata,
    load_project_manifest,
};
use std::collections::HashSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode};

#[derive(Debug, Clone)]
struct CommonOptions {
    mode: BuildMode,
    opt_level: OptLevel,
    output: Option<PathBuf>,
    cache: CacheOverrides,
    owl_home: Option<PathBuf>,
    warn: WarningCliOptions,
    verbose: bool,
}

#[derive(Debug, Clone)]
struct WarningCliOptions {
    filter: WarningFilter,
    deny: HashSet<DiagnosticCode>,
    position: bool,
    no_warn_cats: Vec<String>,
}

#[derive(Debug, Clone)]
struct DebugOptions {
    common: CommonOptions,
    file: Option<String>,
    show_tokens: bool,
    show_ast: bool,
    run_binary: bool,
    emit_ir_only: bool,
}

fn main() -> ExitCode {
    match run_cli() {
        Ok(code) => ExitCode::from(code as u8),
        Err(err) => {
            eprintln!("{}", err.format_color());
            ExitCode::from(1)
        }
    }
}

fn run_cli() -> Result<i32, MireError> {
    let args: Vec<String> = env::args().collect();
    let cwd = env::current_dir().map_err(runtime_err)?;

    if args.len() <= 1 {
        print_help();
        return Ok(1);
    }

    match args[1].as_str() {
        "run" => run_command(&cwd, &args[2..]),
        "build" => build_command(&cwd, &args[2..]),
        "check" => check_command(&cwd, &args[2..]),
        "debug" => debug_command(&cwd, &args[2..]),
        "test" => test_command(&cwd, &args[2..]),

        "help" | "--help" | "-h" => {
            print_help();
            Ok(0)
        }
        "--version" | "-V" => {
            println!("Mire / Avenys v{}", env!("CARGO_PKG_VERSION"));
            Ok(0)
        }
        _ => {
            print_help();
            Ok(1)
        }
    }
}

fn run_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    let (common, file, pass_through) = parse_run_options(cwd, args)?;
    let path = resolve_source_path(cwd, file)?;
    set_owl_home_env(common.owl_home.as_ref());
    let test_roots = read_test_roots(cwd);
    let suppress_warn = is_under_test_path(&path, &test_roots);
    let options = BuildOptions {
        mode: common.mode,
        opt_level: common.opt_level,
        debug_dump: common.verbose,
        output: common
            .output
            .clone()
            .or_else(|| Some(default_binary_path(&path, common.mode))),
        emit_binary: true,
        persist_ir: false,
        import_mode: ImportMode::default(),
        cache: common.cache,
        warning_filter: common.warn.filter,
        deny_warnings: common.warn.deny,
        test_mode: false,
        module_paths: Vec::new(),
    };
    let build = compile_file_with_avenys(&path, &options)?;
    if !suppress_warn && !matches!(options.warning_filter, WarningFilter::Off) {
        emit_warnings(&build, common.warn.position, &common.warn.no_warn_cats);
    }
    let mut cmd = Command::new(&build.binary_path);
    for arg in pass_through {
        cmd.arg(arg);
    }
    let status = cmd.status().map_err(runtime_err)?;
    Ok(status.code().unwrap_or(1))
}

fn build_help() {
    println!("Usage: mire build [file] [options]");
    println!("\nProfiles:");
    println!("  --debug               Build profile debug (default)");
    println!("  --release             Build profile release");
    println!("  -O, --opt-level <n>   0|1|2|3|s|z");
    println!("\nOutput:");
    println!("  -o, --output <file>   Output binary path (default: <input>.out)");
    println!("\nWarnings:");
    println!("  --show-warn           Show warning summary");
    println!("  --position            Show per-file warning locations");
    println!("  --no-warn <cat>       Suppress warning category (repeatable)");
    println!("  -W <code>             Promote warning to error");
    println!("  --deny <code>         Deny specific warning code");
    println!("\nOther:");
    println!("  --owl-home <path>     Override the Owl module cache root");
    println!("  --verbose, -v         Debug dump");
}

fn build_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    if args.iter().any(|a| a == "--help") {
        build_help();
        return Ok(0);
    }
    let (common, file) = parse_common_with_file(cwd, args)?;
    let path = resolve_source_path(cwd, file)?;
    set_owl_home_env(common.owl_home.as_ref());
    let test_roots = read_test_roots(cwd);
    let suppress_warn = is_under_test_path(&path, &test_roots);
    let options = BuildOptions {
        mode: common.mode,
        opt_level: common.opt_level,
        debug_dump: common.verbose,
        output: common
            .output
            .or_else(|| Some(default_binary_path(&path, common.mode))),
        emit_binary: true,
        persist_ir: false,
        import_mode: ImportMode::default(),
        cache: common.cache,
        warning_filter: common.warn.filter,
        deny_warnings: common.warn.deny,
        test_mode: false,
        module_paths: Vec::new(),
    };
    let build = compile_file_with_avenys(&path, &options)?;
    if !suppress_warn && !matches!(options.warning_filter, WarningFilter::Off) {
        emit_warnings(&build, common.warn.position, &common.warn.no_warn_cats);
    }
    println!("{}", build.binary_path.display());
    Ok(0)
}

fn check_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    if args.iter().any(|a| a == "--help") {
        build_help();
        return Ok(0);
    }
    let (common, file) = parse_common_with_file(cwd, args)?;
    let path = resolve_source_path(cwd, file)?;
    set_owl_home_env(common.owl_home.as_ref());
    let test_roots = read_test_roots(cwd);
    let suppress_warn = is_under_test_path(&path, &test_roots);
    let warn_filter_off = matches!(common.warn.filter, WarningFilter::Off);
    let source = fs::read_to_string(&path).map_err(runtime_err)?;
    let loaded = load_program_with_metadata(&path)?;
    let mut program = loaded.program;
    let mut analysis_program = program.clone();
    let _ = analyze_program(&mut analysis_program, &source)?;
    let report = analyze_program_with_warnings_and_origins(
        &mut program,
        &source,
        Some(&path.display().to_string()),
        WarningConfig {
            filter: common.warn.filter,
            deny: common.warn.deny,
        },
        &loaded.statement_origins,
        &path,
    )?;

    let filtered_diags: Vec<_> = report
        .diagnostics
        .iter()
        .filter(|d| !should_suppress(d.code.name(), &common.warn.no_warn_cats))
        .cloned()
        .collect();
    let mut has_error = false;
    if !suppress_warn && !warn_filter_off {
        if common.warn.position {
            for diagnostic in &filtered_diags {
                eprintln!("{}", format_diagnostic(diagnostic, true));
                if matches!(diagnostic.severity, Severity::Error) {
                    has_error = true;
                }
            }
        } else {
            print_warning_summary(&filtered_diags);
            has_error = filtered_diags.iter().any(|d| matches!(d.severity, Severity::Error));
        }
    } else {
        has_error = filtered_diags.iter().any(|d| matches!(d.severity, Severity::Error));
    }
    Ok(if has_error { 1 } else { 0 })
}

fn debug_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    let options = parse_debug_options(cwd, args)?;
    let path = resolve_source_path(cwd, options.file.clone())?;
    set_owl_home_env(options.common.owl_home.as_ref());
    let source = fs::read_to_string(&path).map_err(runtime_err)?;

    if options.show_tokens {
        let tokens = tokenize(&source).map_err(|err| {
            err.with_source(source.clone())
                .with_filename(path.display().to_string())
        })?;
        for token in &tokens {
            println!("{:?}", token);
        }
    }

    if options.show_ast {
        let program = parse(&source).map_err(|err| {
            err.with_source(source.clone())
                .with_filename(path.display().to_string())
        })?;
        println!("{:#?}", program);
    }

    let build = compile_file_with_avenys(
        &path,
        &BuildOptions {
            mode: options.common.mode,
            opt_level: options.common.opt_level,
            debug_dump: true,
            output: options
                .common
                .output
                .clone()
                .or_else(|| Some(default_binary_path(&path, options.common.mode))),
            emit_binary: !options.emit_ir_only,
            persist_ir: true,
            import_mode: ImportMode::default(),
            cache: options.common.cache,
            warning_filter: options.common.warn.filter,
            deny_warnings: options.common.warn.deny,
            test_mode: false,
            module_paths: Vec::new(),
        },
    )?;

    if let Some(ir) = &build.ir_path {
        println!("IR: {}", ir.display());
    }
    if let Some(ir) = &build.optimized_ir_path {
        println!("OPT IR: {}", ir.display());
    }
    if options.run_binary && !options.emit_ir_only {
        let status = Command::new(&build.binary_path)
            .status()
            .map_err(runtime_err)?;
        return Ok(status.code().unwrap_or(1));
    }
    Ok(0)
}

fn test_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    let mut run = true;
    let mut verbose = false;
    let mut jobs: usize = 0;
    let mut owl_home = None;
    let mut paths: Vec<String> = Vec::new();
    let mut opt_level = OptLevel::O0;
    let mut categorize = true;
    let mut show_warn = false;
    let mut position = false;
    let mut no_warn_cats: Vec<String> = Vec::new();

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--help" | "-h" => {
                println!("Usage: mire test [paths...] [options]");
                println!();
                println!("Run integration tests, optionally categorized by directory.");
                println!();
                println!("Options:");
                println!("  --no-run            Compile only, skip execution");
                println!("  --verbose, -v       Show per-test results");
                println!("  --no-categorize     Disable directory-based category grouping");
                println!("  --jobs, -j <n>      Parallel compilation jobs (0 = logical CPUs)");
                println!("  --owl-home <path>   Override the Owl module cache root");
                println!("  -O, --opt-level <n> Optimization level for test binaries (0,1,2,3,s,z)");
                println!("  -r, --release       Shorthand for --opt-level 3");
                println!("  -d, --debug         Shorthand for --opt-level 0 (default)");
                println!("  --show-warn, --sh-warn  Show warnings (summary by default)");
                println!("  --position, --pos       Show warnings per-file (detailed)");
                println!("  --no-warn <cat>         Suppress warning category (repeatable)");
                println!("  --help, -h          Show this help message");
                return Ok(0);
            }
            "--no-run" => run = false,
            "--verbose" | "-v" => verbose = true,
            "--no-categorize" => categorize = false,
            "--show-warn" | "--sh-warn" => show_warn = true,
            "--position" | "--pos" => position = true,
            "--no-warn" => {
                i += 1;
                let cat = args.get(i).ok_or_else(|| runtime_msg("Missing warning category after --no-warn"))?;
                no_warn_cats.push(cat.clone());
            }
            "--jobs" | "-j" => {
                i += 1;
                let value = args.get(i).ok_or_else(|| {
                    runtime_msg("Missing value for --jobs")
                })?;
                jobs = value.parse().map_err(|_| {
                    runtime_msg("--jobs must be a positive integer")
                })?;
            }
            "--owl-home" => {
                i += 1;
                let value = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing value for --owl-home"))?;
                owl_home = Some(PathBuf::from(value));
            }
            "-O" | "--opt-level" => {
                i += 1;
                let value = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing value for --opt-level"))?;
                match OptLevel::parse(value) {
                    Some(level) => opt_level = level,
                    None => return Err(runtime_msg("Invalid opt-level")),
                }
            }
            "-r" | "--release" => opt_level = OptLevel::O3,
            "-d" | "--debug" => opt_level = OptLevel::O0,
            _ => {
                if let Some(val) = args[i].strip_prefix("--jobs=") {
                    jobs = val.parse().map_err(|_| {
                        runtime_msg("--jobs must be a positive integer")
                    })?;
                } else {
                    paths.push(args[i].clone());
                }
            }
        }
        i += 1;
    }

    set_owl_home_env(owl_home.as_ref());

    // --- helpers ---------------------------------------------------
    fn read_owl_test_paths(cwd: &Path) -> Vec<(String, PathBuf)> {
        let manifest_paths = [
            cwd.join("owl.toml"),
            cwd.join("Mire.toml"),
            cwd.join("Avenys.toml"),
        ];
        let mut content = String::new();
        for m in &manifest_paths {
            if let Ok(c) = fs::read_to_string(m) {
                content = c;
                break;
            }
        }
        let mut in_section = String::new();
        let mut found: Vec<(String, String)> = Vec::new();
        for raw in content.lines() {
            let line = raw.trim();
            if line.starts_with('[') && line.ends_with(']') {
                in_section = line[1..line.len() - 1].to_string();
                continue;
            }
            if in_section == "tests" {
                if let Some(v) = kv_string(line, "path") {
                    found.push(("tests".to_string(), v));
                } else if let Some(v) = kv_string(line, "dirs") {
                    for p in parse_array_value(&v) {
                        if !p.is_empty() {
                            found.push(("dirs".to_string(), p));
                        }
                    }
                } else if let Some((key, val)) = parse_generic_kv(line) {
                    found.push((key, val));
                }
            } else if in_section == "paths" {
                if let Some(v) = kv_string(line, "tests") {
                    found.push(("paths".to_string(), v));
                }
            }
        }
        if found.is_empty() {
            found.push(("tests".to_string(), "tests".to_string()));
        }
        found.into_iter().map(|(k, p)| (k, cwd.join(p))).collect()
    }

    fn kv_string(line: &str, key: &str) -> Option<String> {
        let prefix = format!("{}=", key);
        let rest = line.strip_prefix(&prefix)?;
        let rest = rest.trim();
        if rest.starts_with('"') {
            let end = rest[1..].find('"')?;
            return Some(rest[1..1 + end].to_string());
        }
        if rest.starts_with('[') {
            let inner = rest.trim_start_matches('[').trim_end_matches(']');
            for part in inner.split(',') {
                let p = part.trim().trim_matches('"').to_string();
                if !p.is_empty() {
                    return Some(p);
                }
            }
        }
        None
    }

    fn unit_category(base: &Path, file: &Path) -> String {
        let rel = match file.strip_prefix(base) {
            Ok(r) => r,
            Err(_) => return String::new(),
        };
        let comps: Vec<_> = rel.components().collect();
        if comps.len() >= 2 {
            comps[0].as_os_str().to_string_lossy().to_string()
        } else {
            String::new()
        }
    }

    fn find_golden_dirs(root: &Path) -> Vec<PathBuf> {
        let mut dirs = Vec::new();
        let mut stack = vec![root.to_path_buf()];
        while let Some(current) = stack.pop() {
            let Ok(entries) = fs::read_dir(&current) else {
                continue;
            };
            for entry in entries.flatten() {
                let path = entry.path();
                let Ok(ft) = path.metadata() else {
                    continue;
                };
                if ft.is_dir() {
                    stack.push(path.clone());
                } else if path
                    .file_name()
                    .map(|n| n == "program.mire")
                    .unwrap_or(false)
                {
                    let dir = path.parent().unwrap();
                    let has_expect = dir.join("stdout.txt").exists()
                        || dir.join("stderr.txt").exists()
                        || dir.join("exit_code.txt").exists();
                    if has_expect {
                        dirs.push(dir.to_path_buf());
                    }
                }
            }
        }
        dirs
    }

    fn read_opt(path: &Path) -> Option<String> {
        fs::read_to_string(path)
            .ok()
            .map(|s| s.trim_end_matches(['\r', '\n']).to_string())
    }

    fn read_exit(path: &Path) -> Option<i32> {
        fs::read_to_string(path)
            .ok()
            .and_then(|s| s.trim().parse::<i32>().ok())
    }

    fn evaluate_golden(expect: &GoldenExpect, output: &std::process::Output) -> UnitStatus {
        let stdout = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        let code = output.status.code().unwrap_or(-1);
        let mut mismatches: Vec<String> = Vec::new();
        if let Some(exp) = &expect.stdout {
            let got = stdout.trim_end_matches(['\r', '\n']);
            if got != exp {
                mismatches.push(format!(
                    "stdout mismatch:\n    expected: {:?}\n    got:      {:?}",
                    exp, got
                ));
            }
        }
        if let Some(exp) = &expect.stderr {
            let got = stderr.trim_end_matches(['\r', '\n']);
            if got != exp {
                mismatches.push(format!(
                    "stderr mismatch:\n    expected: {:?}\n    got:      {:?}",
                    exp, got
                ));
            }
        }
        if let Some(exp) = expect.exit {
            if code != exp {
                mismatches.push(format!("exit code mismatch: expected {} got {}", exp, code));
            }
        }
        if mismatches.is_empty() {
            UnitStatus::Pass
        } else {
            UnitStatus::Fail(mismatches.join("\n"))
        }
    }

    // --- unit model ------------------------------------------------
    struct GoldenExpect {
        stdout: Option<String>,
        stderr: Option<String>,
        exit: Option<i32>,
    }
    enum UnitStatus {
        Pass,
        Fail(String),
        Compiled,
    }
    struct Unit {
        category: String,
        display: String,
        target_file: PathBuf,
        binary_path: PathBuf,
        skip_run: bool,
        golden: Option<GoldenExpect>,
    }

    let test_dir = cwd.join("bin/.cache/test");
    let _ = fs::create_dir_all(&test_dir);
    let test_bin_dir = cwd.join("bin/debug/test");
    if test_bin_dir.exists() && !test_bin_dir.is_dir() {
        let _ = fs::remove_file(&test_bin_dir);
    }
    let _ = fs::create_dir_all(&test_bin_dir);

    fn is_generic_key(k: &str) -> bool { matches!(k, "tests" | "dirs" | "paths") }

    let mut units: Vec<Unit> = Vec::new();

    let test_roots: Vec<(String, PathBuf)> = if !paths.is_empty() {
        paths.iter().map(|p| ("path".to_string(), cwd.join(p))).collect()
    } else {
        read_owl_test_paths(cwd)
    };

    for (key, root) in &test_roots {
        let use_key_cat = !is_generic_key(key);
        if root.is_file() {
            let display = root.strip_prefix(cwd).unwrap_or(root).display().to_string();
            let source = fs::read_to_string(root).unwrap_or_default();
            let has_main = source.contains("pub fn main");
            let has_test_fn = source.contains("@[test]");
            let relative = root.strip_prefix(cwd).unwrap_or(root);
            let safe_stem = relative.to_string_lossy().replace(['/', '\\'], "_");
            let binary_path = test_bin_dir.join(&safe_stem);
            units.push(Unit {
                category: if use_key_cat { key.clone() } else { String::new() },
                display,
                target_file: root.clone(),
                binary_path,
                skip_run: has_main && !has_test_fn,
                golden: None,
            });
            continue;
        }
        if !root.is_dir() {
            if paths.is_empty() {
                continue;
            }
            eprintln!("warning: test path not found: {}", root.display());
            continue;
        }
        let golden_dirs = find_golden_dirs(root);
        let mut golden_programs: HashSet<PathBuf> = HashSet::new();
        for gd in &golden_dirs {
            golden_programs.insert(gd.join("program.mire"));
        }
        let mut files = walkdir(root, "*.mire")?;
        files.sort();
        for file in files {
            if golden_programs.contains(&file) {
                continue;
            }
            let display = file.strip_prefix(cwd).unwrap_or(&file).display().to_string();
            let source = fs::read_to_string(&file).unwrap_or_default();
            let has_main = source.contains("pub fn main");
            let has_load = source.contains("load ");
            let has_test_fn = source.contains("@[test]");
            let relative = file.strip_prefix(cwd).unwrap_or(&file);
            let safe_stem = relative.to_string_lossy().replace(['/', '\\'], "_");
            let (target_file, _stem) = if !has_main {
                let test_path = test_dir.join(format!("{}.mire", safe_stem));
                if has_load || has_test_fn {
                    let _ = fs::write(&test_path, &source);
                } else {
                    let patched = format!("pub fn main: () {{\n{}\n}}\n", source);
                    let _ = fs::write(&test_path, &patched);
                }
                (test_path, safe_stem.clone())
            } else {
                (file.clone(), safe_stem.clone())
            };
            let binary_path = test_bin_dir.join(&safe_stem);
            let category = if use_key_cat { key.clone() } else { unit_category(root, &file) };
            units.push(Unit {
                category,
                display,
                target_file,
                binary_path,
                skip_run: has_main && !has_test_fn,
                golden: None,
            });
        }
        for gd in golden_dirs {
            let display = gd.strip_prefix(cwd).unwrap_or(&gd).display().to_string();
            let safe_stem = gd
                .strip_prefix(cwd)
                .unwrap_or(&gd)
                .to_string_lossy()
                .replace(['/', '\\'], "_");
            let binary_path = test_bin_dir.join(format!("golden_{}", safe_stem));
            let expect = GoldenExpect {
                stdout: read_opt(&gd.join("stdout.txt")),
                stderr: read_opt(&gd.join("stderr.txt")),
                exit: read_exit(&gd.join("exit_code.txt")),
            };
            let category = if use_key_cat { key.clone() } else { unit_category(root, &gd.join("program.mire")) };
            units.push(Unit {
                category,
                display,
                target_file: gd.join("program.mire"),
                binary_path,
                skip_run: false,
                golden: Some(expect),
            });
        }
    }

    // backward-compat: run the project's own entry as a smoke test
    if paths.is_empty() {
        for candidate in [cwd.join("code/main.mire"), cwd.join("main.mire")] {
            if candidate.exists() {
                let display = candidate
                    .strip_prefix(cwd)
                    .unwrap_or(&candidate)
                    .display()
                    .to_string();
                let source = fs::read_to_string(&candidate).unwrap_or_default();
                let has_main = source.contains("pub fn main");
                let has_test_fn = source.contains("@[test]");
                let relative = candidate.strip_prefix(cwd).unwrap_or(&candidate);
                let safe_stem = relative.to_string_lossy().replace(['/', '\\'], "_");
                let binary_path = test_bin_dir.join(&safe_stem);
                units.push(Unit {
                    category: String::new(),
                    display,
                    target_file: candidate.clone(),
                    binary_path,
                    skip_run: has_main && !has_test_fn,
                    golden: None,
                });
                break;
            }
        }
    }

    if units.is_empty() {
        println!("no tests found");
        return Ok(0);
    }

    let jobs = if jobs == 0 {
        std::thread::available_parallelism()
            .map(|n| n.get())
            .unwrap_or(4)
            .max(1)
    } else {
        jobs.max(1)
    };

    let mut results: Vec<(String, String, UnitStatus)> = Vec::new();
    let mut all_warnings: Vec<Diagnostic> = Vec::new();

    let warn_filter = if show_warn {
        WarningFilter::All
    } else {
        WarningFilter::Off
    };

    for chunk in units.chunks(jobs) {
        let compile_results: Vec<Option<Result<BuildResult, MireError>>> =
            std::thread::scope(|s| {
                let mut handles = Vec::with_capacity(chunk.len());
                for u in chunk {
                    let options = BuildOptions {
                        mode: BuildMode::Debug,
                        opt_level,
                        output: Some(u.binary_path.clone()),
                        emit_binary: run,
                        persist_ir: false,
                        import_mode: ImportMode::default(),
                        cache: Default::default(),
                        warning_filter: warn_filter.clone(),
                        deny_warnings: HashSet::new(),
                        test_mode: true,
                        module_paths: Vec::new(),
                        ..Default::default()
                    };
                    handles.push(s.spawn(move || compile_file_with_avenys(&u.target_file, &options)));
                }
                handles.into_iter().map(|h| Some(h.join().unwrap())).collect()
            });

        for (u, result) in chunk.iter().zip(compile_results.iter()) {
            match result {
                Some(Ok(build)) => {
                    let filtered: Vec<_> = build
                        .warnings_raw
                        .iter()
                        .filter(|d| !should_suppress(d.code.name(), &no_warn_cats))
                        .cloned()
                        .collect();
                    if show_warn && position {
                        for d in &filtered {
                            print_warning_detailed(d, true);
                        }
                    } else if show_warn {
                        all_warnings.extend(filtered);
                    }
                    if let Some(expect) = &u.golden {
                        if run {
                            match Command::new(&build.binary_path).output() {
                                Ok(output) => {
                                    let status = evaluate_golden(expect, &output);
                                    results.push((u.category.clone(), u.display.clone(), status));
                                }
                                Err(e) => results.push((
                                    u.category.clone(),
                                    u.display.clone(),
                                    UnitStatus::Fail(format!("run error: {}", e)),
                                )),
                            }
                        } else {
                            results.push((
                                u.category.clone(),
                                u.display.clone(),
                                UnitStatus::Compiled,
                            ));
                        }
                    } else if run && !u.skip_run {
                        match Command::new(&build.binary_path).output() {
                            Ok(output) => {
                                let stdout = String::from_utf8_lossy(&output.stdout);
                                let mut file_failed = 0u32;
                                for line in stdout.lines() {
                                    let trimmed = line.trim();
                                    if trimmed.starts_with("[FAIL]") {
                                        if verbose {
                                            println!("  {}", trimmed);
                                        }
                                        file_failed += 1;
                                    } else if verbose {
                                        println!("  {}", trimmed);
                                    }
                                }
                                let status = if file_failed == 0 {
                                    UnitStatus::Pass
                                } else {
                                    UnitStatus::Fail(format!(
                                        "{} assertion(s) failed",
                                        file_failed
                                    ))
                                };
                                results.push((u.category.clone(), u.display.clone(), status));
                            }
                            Err(e) => results.push((
                                u.category.clone(),
                                u.display.clone(),
                                UnitStatus::Fail(format!("run error: {}", e)),
                            )),
                        }
                    } else {
                        results.push((u.category.clone(), u.display.clone(), UnitStatus::Compiled));
                    }
                }
                Some(Err(e)) => {
                    results.push((
                        u.category.clone(),
                        u.display.clone(),
                        UnitStatus::Fail(format!("{}", e)),
                    ));
                }
                None => {
                    results.push((
                        u.category.clone(),
                        u.display.clone(),
                        UnitStatus::Fail("unknown error".to_string()),
                    ));
                }
            }
        }
    }

    // --- grouped, categorized output ------------------------------
    let mut categories: Vec<String> = results.iter().map(|(c, _, _)| c.clone()).collect();
    categories.sort();
    categories.dedup();

    let mut global_passed = 0u32;
    let mut global_failed = 0u32;
    let mut global_skipped = 0u32;

    println!();
    for cat in &categories {
        if categorize && !cat.is_empty() {
            println!("[{}]", cat);
        }
        for (c, display, status) in &results {
            if c != cat {
                continue;
            }
            let indented = categorize && !cat.is_empty();
            match status {
                UnitStatus::Pass => {
                    global_passed += 1;
                    if indented {
                        println!("  {} ... ok", display);
                    } else {
                        println!("test {} ... ok", display);
                    }
                }
                UnitStatus::Compiled => {
                    global_passed += 1;
                    if indented {
                        println!("  {} ... ok (compiled)", display);
                    } else {
                        println!("test {} ... ok (compiled)", display);
                    }
                }
                UnitStatus::Fail(detail) => {
                    global_failed += 1;
                    if indented {
                        println!("  {} ... FAILED", display);
                    } else {
                        println!("test {} ... FAILED", display);
                    }
                    for line in detail.lines() {
                        println!("      {}", line);
                    }
                }
                _ => {}
            }
        }
    }

    if show_warn && !position && !all_warnings.is_empty() {
        println!();
        print_warning_summary(&all_warnings);
    }

    let total = global_passed + global_failed + global_skipped;
    println!();
    println!("test result:");
    println!(
        "Ok: {} - Passed: {} - Failed: {} - Filtered Out: {}",
        global_passed, global_passed, global_failed, global_skipped
    );
    println!("Total: {}", total);
    let exit_code = if global_failed == 0 { 0 } else { 1 };

    Ok(exit_code)
}

/// Returns true if `path` is underneath any of `test_roots`.
fn is_under_test_path(path: &Path, test_roots: &[PathBuf]) -> bool {
    test_roots.iter().any(|root| path.starts_with(root))
}

/// Read owl.toml [tests] keys to discover test root directories.
fn read_test_roots(cwd: &Path) -> Vec<PathBuf> {
    let manifest_paths = [
        cwd.join("owl.toml"),
        cwd.join("Mire.toml"),
        cwd.join("Avenys.toml"),
    ];
    let mut content = String::new();
    for m in &manifest_paths {
        if let Ok(c) = fs::read_to_string(m) {
            content = c;
            break;
        }
    }
    if content.is_empty() {
        return Vec::new();
    }
    let mut in_section = String::new();
    let mut found: Vec<String> = Vec::new();
    for raw in content.lines() {
        let line = raw.trim();
        if line.starts_with('[') && line.ends_with(']') {
            in_section = line[1..line.len() - 1].to_string();
            continue;
        }
        if in_section == "tests" || in_section == "paths" {
            if let Some(v) = kv_string(line, "path") {
                found.push(v);
            } else if let Some(v) = kv_string(line, "dirs") {
                for p in parse_array_value(&v) {
                    if !p.is_empty() {
                        found.push(p);
                    }
                }
            } else if let Some((_key, val)) = parse_generic_kv(line) {
                found.push(val);
            }
        }
    }
    if found.is_empty() {
        found.push("tests".to_string());
    }
    found.into_iter().map(|p| cwd.join(p)).collect()
}

fn parse_array_value(s: &str) -> Vec<String> {
    let inner = s.trim_start_matches('[').trim_end_matches(']');
    inner
        .split(',')
        .map(|part| part.trim().trim_matches('"').to_string())
        .filter(|p| !p.is_empty())
        .collect()
}

fn parse_generic_kv(line: &str) -> Option<(String, String)> {
    let eq_pos = line.find('=')?;
    let key = line[..eq_pos].trim().to_string();
    if key.starts_with('[') || key.is_empty() {
        return None;
    }
    let val = line[eq_pos + 1..].trim();
    let val = val.trim_matches('"').to_string();
    Some((key, val))
}

fn kv_string(line: &str, key: &str) -> Option<String> {
    let prefix = format!("{}=", key);
    let rest = line.strip_prefix(&prefix)?;
    let rest = rest.trim();
    if rest.starts_with('"') {
        let end = rest[1..].find('"')?;
        return Some(rest[1..1 + end].to_string());
    }
    if rest.starts_with('[') {
        let inner = rest.trim_start_matches('[').trim_end_matches(']');
        for part in inner.split(',') {
            let p = part.trim().trim_matches('"').to_string();
            if !p.is_empty() {
                return Some(p);
            }
        }
    }
    None
}

/// Print warnings as a per-category summary table.
fn print_warning_summary(raw: &[Diagnostic]) {
    use std::collections::BTreeMap;
    let mut counts: BTreeMap<String, usize> = BTreeMap::new();
    for d in raw {
        let name = d.code.name().to_string();
        *counts.entry(name).or_insert(0) += 1;
    }
    if counts.is_empty() {
        return;
    }
    eprintln!(
        "╭─[ warnings summary ]"
    );
    let mut total = 0usize;
    for (i, (name, cnt)) in counts.iter().enumerate() {
        total += cnt;
        eprintln!("│ {:>2} │  {} ............ {}",
            i + 1,
            name.replace('_', "-"),
            cnt,
        );
    }
    eprintln!("│ {:>2} │  Total ............... {}", counts.len() + 1, total);
    eprintln!("╰─ Use --position (or --pos) to see per-file details.");
}

/// Print one warning in detailed format.
fn print_warning_detailed(d: &Diagnostic, use_color: bool) {
    eprint!("{}", format_diagnostic(d, use_color));
}

fn should_suppress(code_name: &str, suppressed: &[String]) -> bool {
    let hyphenated = code_name.replace('_', "-");
    suppressed.iter().any(|s| s == code_name || s == &hyphenated)
}

/// Print warnings from a BuildResult according to `position` flag.
fn emit_warnings(build: &BuildResult, position: bool, no_warn_cats: &[String]) {
    let filtered: Vec<_> = build
        .warnings_raw
        .iter()
        .filter(|d| !should_suppress(d.code.name(), no_warn_cats))
        .cloned()
        .collect();
    if position {
        for d in &filtered {
            print_warning_detailed(d, true);
        }
    } else {
        print_warning_summary(&filtered);
    }
}

fn walkdir(dir: &Path, _pattern: &str) -> Result<Vec<PathBuf>, MireError> {
    let mut results = Vec::new();
    if !dir.is_dir() {
        return Ok(results);
    }
    let mut stack = vec![dir.to_path_buf()];
    while let Some(current) = stack.pop() {
        let Ok(entries) = fs::read_dir(&current) else {
            continue;
        };
        for entry in entries {
            let Ok(entry) = entry else { continue };
            let Ok(ft) = entry.file_type() else { continue };
            if ft.is_symlink() {
                continue;
            }
            let path = entry.path();
            if path.is_dir() {
                stack.push(path);
            } else if let Some(ext) = path.extension()
                && ext == "mire"
            {
                results.push(path);
            }
        }
    }
    Ok(results)
}

fn parse_run_options(
    cwd: &Path,
    args: &[String],
) -> Result<(CommonOptions, Option<String>, Vec<String>), MireError> {
    let mut split = 0usize;
    while split < args.len() {
        if args[split] == "--" {
            break;
        }
        split += 1;
    }
    let (left, right) = if split < args.len() {
        (&args[..split], args[split + 1..].to_vec())
    } else {
        (args, Vec::new())
    };

    let (common, file) = parse_common_with_file(cwd, left)?;
    Ok((common, file, right))
}

fn parse_common_with_file(
    cwd: &Path,
    args: &[String],
) -> Result<(CommonOptions, Option<String>), MireError> {
    let mut mode = BuildMode::Debug;
    let mut opt_level = OptLevel::O0;
    let mut output = None;
    let mut file = None;
    let mut cache = CacheOverrides::default();
    let mut owl_home = None;
    let mut verbose = false;
    let mut show_warn = false;
    let mut position = false;
    let mut warn_codes = HashSet::new();
    let mut deny_codes = HashSet::new();
    let mut no_warn_cats: Vec<String> = Vec::new();

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--debug" => {
                mode = BuildMode::Debug;
                if matches!(opt_level, OptLevel::O0) {
                    opt_level = OptLevel::O0;
                }
            }
            "--release" => {
                mode = BuildMode::Release;
                if matches!(opt_level, OptLevel::O0) {
                    opt_level = OptLevel::O3;
                }
            }
            "-O" | "--opt-level" => {
                i += 1;
                let level = args.get(i).ok_or_else(|| {
                    runtime_msg("Missing optimization level after -O/--opt-level")
                })?;
                opt_level = OptLevel::parse(level)
                    .ok_or_else(|| runtime_msg("Invalid optimization level, use 0/1/2/3/s/z"))?;
            }
            flag if flag.starts_with("-O") && flag.len() > 2 => {
                opt_level = OptLevel::parse(&flag[2..])
                    .ok_or_else(|| runtime_msg("Invalid optimization level, use 0/1/2/3/s/z"))?;
            }
            "-o" | "--output" => {
                i += 1;
                let value = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing output path after -o/--output"))?;
                output = Some(PathBuf::from(value));
            }
            "--owl-home" => {
                i += 1;
                let value = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing value for --owl-home"))?;
                owl_home = Some(PathBuf::from(value));
            }
            "--cache-max-units" => {
                i += 1;
                let value = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing value for --cache-max-units"))?;
                let parsed = value
                    .parse::<usize>()
                    .map_err(|_| runtime_msg("Invalid --cache-max-units value"))?;
                cache.max_units = Some(parsed);
            }
            "--no-analysis-cache" => cache.analysis_cache = Some(false),
            "--analysis-cache" => cache.analysis_cache = Some(true),
            "--show-warn" | "--sh-warn" => show_warn = true,
            "--position" | "--pos" => position = true,
            "--warnings-as-errors" | "--deny-warnings" => {
                for code in [DiagnosticCode::W0001, DiagnosticCode::W0002, DiagnosticCode::W0003, DiagnosticCode::W0004, DiagnosticCode::W0005, DiagnosticCode::W0034, DiagnosticCode::W0039] {
                    deny_codes.insert(code);
                }
            }
            "--no-warn" => {
                i += 1;
                let cat = args.get(i).ok_or_else(|| runtime_msg("Missing warning category after --no-warn"))?;
                no_warn_cats.push(cat.clone());
            }
            "-W" => {
                i += 1;
                let code = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing warning code after -W"))?;
                warn_codes.insert(parse_warning_code(code)?);
            }
            "--deny" => {
                i += 1;
                let code = args
                    .get(i)
                    .ok_or_else(|| runtime_msg("Missing warning code after --deny"))?;
                deny_codes.insert(parse_warning_code(code)?);
            }
            "--verbose" | "-v" => verbose = true,
            "--progress" => {
                unsafe { std::env::set_var("OWL_PROGRESS", "1") };
            }
            value if value.starts_with('-') => {
                return Err(runtime_msg(&format!("Unknown option: {value}")));
            }
            value => {
                if file.is_some() {
                    return Err(runtime_msg("Only one input file is supported"));
                }
                file = Some(value.to_string());
            }
        }
        i += 1;
    }

    if !matches!(mode, BuildMode::Release) && !matches!(opt_level, OptLevel::O0) {
        mode = BuildMode::Release;
    }

    let warning_filter = if show_warn {
        WarningFilter::All
    } else if !warn_codes.is_empty() {
        WarningFilter::Codes(warn_codes)
    } else {
        WarningFilter::Off
    };

    if file.is_none() {
        file = default_entry_from_manifest(cwd)?;
    }

    Ok((
        CommonOptions {
            mode,
            opt_level,
            output,
            cache,
            owl_home,
            warn: WarningCliOptions {
                filter: warning_filter,
                deny: deny_codes,
                position,
                no_warn_cats,
            },
            verbose,
        },
        file,
    ))
}

fn parse_debug_options(cwd: &Path, args: &[String]) -> Result<DebugOptions, MireError> {
    let mut show_tokens = false;
    let mut show_ast = false;
    let mut run_binary = false;
    let mut emit_ir_only = false;
    let mut filtered = Vec::new();

    for arg in args {
        match arg.as_str() {
            "--tokens" | "-t" => show_tokens = true,
            "--ast" | "-p" => show_ast = true,
            "--run" | "-r" => run_binary = true,
            "--ir" => emit_ir_only = true,
            _ => filtered.push(arg.clone()),
        }
    }

    let (mut common, file) = parse_common_with_file(cwd, &filtered)?;
    common.mode = BuildMode::Debug;
    if matches!(common.opt_level, OptLevel::O0) {
        common.opt_level = OptLevel::O1;
    }

    Ok(DebugOptions {
        common,
        file,
        show_tokens,
        show_ast,
        run_binary,
        emit_ir_only,
    })
}

fn default_entry_from_manifest(cwd: &Path) -> Result<Option<String>, MireError> {
    let project_root = match find_project_root(cwd) {
        Some(root) => root,
        None => return Ok(None),
    };
    let manifest = load_project_manifest(&project_root)?;
    let entry = manifest.map(|m| m.project.entry).unwrap_or_default();
    let path = project_root.join(&entry);
    Ok(Some(path.to_string_lossy().to_string()))
}

fn resolve_source_path(cwd: &Path, file: Option<String>) -> Result<PathBuf, MireError> {
    let file = file.ok_or_else(|| {
        runtime_msg("No input file provided and no `entry` was found in owl.toml")
    })?;
    let path = PathBuf::from(&file);
    let resolved = if path.is_absolute() {
        path
    } else {
        cwd.join(path)
    };
    if !resolved.exists() {
        return Err(runtime_msg(&format!(
            "Input file not found: {}",
            resolved.display()
        )));
    }
    Ok(resolved)
}

fn default_binary_path(source_path: &Path, mode: BuildMode) -> PathBuf {
    let stem = source_path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("main");
    default_output_dir(source_path, mode).join(stem)
}

fn parse_warning_code(value: &str) -> Result<DiagnosticCode, MireError> {
    match value.trim().to_ascii_uppercase().as_str() {
        "W0001" => Ok(DiagnosticCode::W0001),
        "W0002" => Ok(DiagnosticCode::W0002),
        "W0003" => Ok(DiagnosticCode::W0003),
        "W0004" => Ok(DiagnosticCode::W0004),
        "W0005" => Ok(DiagnosticCode::W0005),
        "W0006" => Ok(DiagnosticCode::W0006),
        "W0007" => Ok(DiagnosticCode::W0007),
        "W0008" => Ok(DiagnosticCode::W0008),
        "W0009" => Ok(DiagnosticCode::W0009),
        "W0010" => Ok(DiagnosticCode::W0010),
        "W0011" => Ok(DiagnosticCode::W0011),
        "W0012" => Ok(DiagnosticCode::W0012),
        "W0013" => Ok(DiagnosticCode::W0013),
        "W0014" => Ok(DiagnosticCode::W0014),
        "W0017" => Ok(DiagnosticCode::W0017),
        "W0018" => Ok(DiagnosticCode::W0018),
        "W0019" => Ok(DiagnosticCode::W0019),
        "W0021" => Ok(DiagnosticCode::W0021),
        "W0024" => Ok(DiagnosticCode::W0024),
        "W0025" => Ok(DiagnosticCode::W0025),
        "W0034" => Ok(DiagnosticCode::W0034),
        "W0035" => Ok(DiagnosticCode::W0035),
        "W0036" => Ok(DiagnosticCode::W0036),
        "W0037" => Ok(DiagnosticCode::W0037),
        "W0038" => Ok(DiagnosticCode::W0038),
        "W0039" => Ok(DiagnosticCode::W0039),
        "W0040" => Ok(DiagnosticCode::W0040),
        _ => Err(runtime_msg("Warning code must look like W0001")),
    }
}

fn runtime_msg(message: &str) -> MireError {
    MireError::runtime(message.to_string())
}

fn runtime_err(err: std::io::Error) -> MireError {
    MireError::runtime(err.to_string())
}

fn print_help() {
    println!("Mire / Avenys v{}", env!("CARGO_PKG_VERSION"));
    println!("Usage: mire <run|build|check|debug> [file] [options]\n");
    println!("Mire is the Avenys compiler. For project management, dependencies,");
    println!("and scaffolding, use Owl (owl new / owl run / owl import).\n");
    println!("Profiles:");
    println!("  --debug               Build profile debug (default)");
    println!("  --release             Build profile release");
    println!("  -O, --opt-level <n>   0|1|2|3|s|z");
    println!("  --owl-home <path>     Override the Owl module cache root");
    println!("\nWarnings (for build/check/run):");
    println!("  --show-warn           Show warning summary");
    println!("  --position            Show per-file warning locations");
    println!("  --no-warn <cat>       Suppress warning category (repeatable)");
    println!("  -W <code>             Promote warning to error");
    println!("  --deny <code>         Deny specific warning code");
    println!("\nCommands:");
    println!("  run [file] [-- args]  Compile + execute");
    println!("  build [file]          Compile only");
    println!("  check [file]          Analyze only");
    println!("  debug [file]          Debug build, emits IR");
    println!("  test [paths...]       Run integration tests from tests/");
    println!("    --no-run            Compile only, skip execution");
    println!("    --verbose, -v       Show per-test results");
    println!("    --show-warn         Show warning summary");
    println!("    --position          Show per-file warning locations");
    println!("    --jobs, -j <n>      Parallel compilation jobs (0 = logical CPUs)");
}

fn set_owl_home_env(path: Option<&PathBuf>) {
    if let Some(path) = path {
        unsafe {
            std::env::set_var("MIRE_OWL_HOME", path);
        }
    }
}
