use mire::error::diagnostic::{DiagnosticCode, Severity, WarningFilter};
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
    let mut cmd = Command::new(&build.binary_path);
    for arg in pass_through {
        cmd.arg(arg);
    }
    let status = cmd.status().map_err(runtime_err)?;
    Ok(status.code().unwrap_or(1))
}

fn build_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    let (common, file) = parse_common_with_file(cwd, args)?;
    let path = resolve_source_path(cwd, file)?;
    set_owl_home_env(common.owl_home.as_ref());
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
    println!("{}", build.binary_path.display());
    Ok(0)
}

fn check_command(cwd: &Path, args: &[String]) -> Result<i32, MireError> {
    let (common, file) = parse_common_with_file(cwd, args)?;
    let path = resolve_source_path(cwd, file)?;
    set_owl_home_env(common.owl_home.as_ref());
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

    let mut has_error = false;
    for diagnostic in &report.diagnostics {
        eprintln!("{}", format_diagnostic(diagnostic, true));
        if matches!(diagnostic.severity, Severity::Error) {
            has_error = true;
        }
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

    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--help" | "-h" => {
                println!("Usage: mire test [paths...] [options]");
                println!();
                println!("Run integration tests from tests/");
                println!();
                println!("Options:");
                println!("  --no-run            Compile only, skip execution");
                println!("  --verbose, -v       Show per-test results");
                println!("  --jobs, -j <n>      Parallel compilation jobs (0 = logical CPUs)");
                println!("  --owl-home <path>   Override the Owl module cache root");
                println!("  -O, --opt-level <n> Optimization level for test binaries (0,1,2,3,s,z)");
                println!("  -r, --release       Shorthand for --opt-level 3");
                println!("  -d, --debug         Shorthand for --opt-level 0 (default)");
                println!("  --help, -h          Show this help message");
                return Ok(0);
            }
            "--no-run" => run = false,
            "--verbose" | "-v" => verbose = true,
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

    let mut test_files: Vec<PathBuf> = Vec::new();

    if !paths.is_empty() {
        for p in &paths {
            let path = cwd.join(p);
            if path.is_dir() {
                let mut entries: Vec<_> = walkdir(&path, "*.mire")?;
                entries.sort();
                test_files.extend(entries);
            } else if path.is_file() {
                test_files.push(path);
            } else {
                eprintln!("warning: test path not found: {}", path.display());
            }
        }
    } else {
        let tests_dir = cwd.join("tests");
        if tests_dir.is_dir() {
            let mut entries: Vec<_> = walkdir(&tests_dir, "*.mire")?;
            entries.sort();
            test_files = entries;
        }
        let main_candidates = [cwd.join("code/main.mire"), cwd.join("main.mire")];
        for candidate in &main_candidates {
            if candidate.exists() {
                test_files.push(candidate.clone());
                break;
            }
        }
    }

    if test_files.is_empty() {
        println!("no tests found");
        return Ok(0);
    }

    struct TestWork {
        display: String,
        target_file: PathBuf,
        binary_path: PathBuf,
        skip_run: bool,
    }

    let mut global_passed = 0u32;
    let mut global_failed = 0u32;
    let mut global_skipped = 0u32;
    let test_dir = cwd.join("bin/.cache/test");
    let _ = fs::create_dir_all(&test_dir);
    let test_bin_dir = cwd.join("bin/debug/test");
    if test_bin_dir.exists() && !test_bin_dir.is_dir() {
        let _ = fs::remove_file(&test_bin_dir);
    }
    let _ = fs::create_dir_all(&test_bin_dir);
    let mut work_items: Vec<TestWork> = Vec::new();

    for file in &test_files {
        let display = file.strip_prefix(cwd).unwrap_or(file).display().to_string();

        if !file.exists() {
            if verbose {
                println!("FAILED: {} - file not found", display);
            }
            global_failed += 1;
            continue;
        }

        let source = fs::read_to_string(file).unwrap_or_default();
        let has_main = source.contains("pub fn main");
        let has_load = source.contains("load ");
        let has_test_fn = source.contains("@[test]");

        let (target_file, stem) = if !has_main {
            let relative = file.strip_prefix(cwd).unwrap_or(file);
            let safe_stem = relative.to_string_lossy().replace('/', "_").replace('\\', "_");
            let test_path = test_dir.join(format!("{}.mire", safe_stem));
            if has_load || has_test_fn {
                let _ = fs::write(&test_path, &source);
            } else {
                let patched = format!("pub fn main: () {{\n{}\n}}\n", source);
                let _ = fs::write(&test_path, &patched);
            }
            (test_path, safe_stem)
        } else {
            let relative = file.strip_prefix(cwd).unwrap_or(file);
            let safe_stem = relative.to_string_lossy().replace('/', "_").replace('\\', "_");
            (file.clone(), safe_stem)
        };

        let binary_path = cwd.join("bin/debug/test").join(&stem);

        work_items.push(TestWork {
            display,
            target_file,
            binary_path,
            skip_run: has_main && !has_test_fn,
        });
    }

    let jobs = if jobs == 0 {
        std::thread::available_parallelism()
            .map(|n| n.get())
            .unwrap_or(4)
            .max(1)
    } else {
        jobs.max(1)
    };

    for chunk in work_items.chunks(jobs) {
        let compile_results: Vec<Option<Result<BuildResult, MireError>>> =
            std::thread::scope(|s| {
                let mut handles = Vec::with_capacity(chunk.len());
                for work in chunk {
                    let options = BuildOptions {
                        mode: BuildMode::Debug,
                        opt_level,
                        output: Some(work.binary_path.clone()),
                        emit_binary: run,
                        persist_ir: false,
                        import_mode: ImportMode::default(),
                        cache: Default::default(),
                        warning_filter: WarningFilter::Default,
                        deny_warnings: HashSet::new(),
                        test_mode: true,
                        module_paths: Vec::new(),
                    ..Default::default()
                    };
                    handles.push(s.spawn(move || {
                        compile_file_with_avenys(&work.target_file, &options)
                    }));
                }
                handles.into_iter().map(|h| Some(h.join().unwrap())).collect()
            });

        for (work, result) in chunk.iter().zip(compile_results.iter()) {
            match result {
                Some(Ok(build)) => {
                    for w in &build.warnings {
                        eprint!("{}", w);
                    }
                    if run && !work.skip_run {
                        match Command::new(&build.binary_path).output() {
                            Ok(output) => {
                                let stdout = String::from_utf8_lossy(&output.stdout);
                                let mut file_passed = 0u32;
                                let mut file_failed = 0u32;
                                let mut file_skipped = 0u32;
                                for line in stdout.lines() {
                                    let trimmed = line.trim();
                                    if trimmed.starts_with("[PASS]") {
                                        if verbose {
                                            println!("  {}", trimmed);
                                        }
                                        file_passed += 1;
                                    } else if trimmed.starts_with("[FAIL]") {
                                        if verbose {
                                            println!("  {}", trimmed);
                                        }
                                        file_failed += 1;
                                    } else if trimmed.starts_with("[SKIP]") {
                                        if verbose {
                                            println!("  {}", trimmed);
                                        }
                                        file_skipped += 1;
                                    } else if !trimmed.is_empty() && verbose {
                                        println!("  {}", trimmed);
                                    }
                                }
                                println!(
                                    "test {} ... {}",
                                    work.display,
                                    if file_failed == 0 { "ok" } else { "FAILED" }
                                );
                                global_passed += file_passed;
                                global_failed += file_failed;
                                global_skipped += file_skipped;
                            }
                            Err(e) => {
                                println!("test {} ... FAILED (run error: {})", work.display, e);
                                global_failed += 1;
                            }
                        }
                    } else {
                        let tag = if work.skip_run { "(no tests)" } else { "(compiled)" };
                        println!("test {} ... ok {}", work.display, tag);
                        global_passed += 1;
                    }
                }
                Some(Err(e)) => {
                    println!("test {} ... FAILED ({})", work.display, e);
                    global_failed += 1;
                }
                None => {
                    println!("test {} ... FAILED (unknown error)", work.display);
                    global_failed += 1;
                }
            }
        }
    }

    let total = global_passed + global_failed + global_skipped;
    let ok_count = global_passed;
    println!();
    println!("test result:");
    println!(
        "Ok: {} - Passed: {} - Failed: {} - Filtered Out: {}",
        ok_count, global_passed, global_failed, global_skipped
    );
    println!("Total: {}", total);
    let exit_code = if global_failed == 0 { 0 } else { 1 };

    Ok(exit_code)
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
    let mut warn_all = false;
    let mut warn_codes = HashSet::new();
    let mut deny_codes = HashSet::new();

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
            "--warn-all" => warn_all = true,
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

    let warning_filter = if warn_all {
        WarningFilter::All
    } else if warn_codes.is_empty() {
        WarningFilter::Default
    } else {
        WarningFilter::Codes(warn_codes)
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
    println!("\nCommands:");
    println!("  run [file] [-- args]  Compile + execute");
    println!("  build [file]          Compile only");
    println!("  check [file]          Analyze only");
    println!("  debug [file]          Debug build, emits IR");
    println!("  test [paths...]       Run integration tests from tests/");
    println!("    --no-run            Compile only, skip execution");
    println!("    --verbose, -v       Show per-test results");
    println!("    --jobs, -j <n>      Parallel compilation jobs (0 = logical CPUs)");
}

fn set_owl_home_env(path: Option<&PathBuf>) {
    if let Some(path) = path {
        unsafe {
            std::env::set_var("MIRE_OWL_HOME", path);
        }
    }
}
