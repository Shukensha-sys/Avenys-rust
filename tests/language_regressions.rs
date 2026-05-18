use mire::parser::ast::{DataType, Expression, Statement};
use mire::{
    BuildMode, BuildOptions, ErrorKind, MireError, OptLevel, analyze_program, cache_file_path,
    check_program_types, compile_file_with_avenys, load_program_from_file,
    load_program_with_metadata, parse,
};
use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::thread;
use std::time::Duration;
use std::time::{SystemTime, UNIX_EPOCH};

fn expect_analysis_error(source: &str) -> String {
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source)
        .expect_err("program should fail analysis")
        .to_string()
}

fn expect_compile_error_from_source(test_name: &str, filename: &str, source: &str) -> MireError {
    let root = make_temp_project_root(test_name);
    let source_path = root.join(filename);
    fs::write(&source_path, source).expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect_err("compilation should fail")
}

#[test]
fn undefined_identifier_in_regular_call_is_not_coerced_to_string() {
    let err = expect_analysis_error("pub fn main: () {\nuse len(missing)\n}\n");
    assert!(err.contains("Unknown identifier 'missing'"), "{err}");
}

#[test]
fn immutable_reassignment_still_errors() {
    let err = expect_analysis_error("pub fn main: () {\nset x = 1\nset x = 2\n}\n");
    assert!(
        err.contains("Cannot reassign immutable variable 'x'"),
        "{err}"
    );
}

#[test]
fn unknown_identifier_error_for_removed_keyword_add() {
    let result: Result<_, MireError> = parse("add std\npub fn main: () {}\n");
    let err = result.expect_err("source should fail to parse");
    let err_str = err.to_string();
    assert!(
        err_str.contains("Legacy `add` imports are no longer supported"),
        "{err_str}"
    );
}

#[test]
fn backend_limitation_errors_render_with_backend_kind() {
    let rendered = MireError::new(ErrorKind::Backend {
        message: "Avenys does not yet lower expression Tuple(...)".to_string(),
    })
    .to_string();

    assert!(rendered.contains("error[backend]"), "{rendered}");
    assert!(rendered.contains("Backend Limitation"), "{rendered}");
    assert!(
        rendered.contains("frontend accepted this program")
            || rendered.contains("current Avenys backend cannot lower"),
        "{rendered}"
    );
}

#[test]
fn compile_reports_lexer_error_kind_and_filename() {
    let err = expect_compile_error_from_source(
        "mire_diag_lexer_kind_filename",
        "lexer_error.mire",
        "pub fn main: () {\n    set x = @#$%\n}\n",
    );

    assert!(matches!(err.kind, ErrorKind::Lexer { .. }));
    assert!(
        err.filename()
            .as_deref()
            .is_some_and(|name| name.ends_with("lexer_error.mire"))
    );
    let rendered = err.to_string();
    assert!(rendered.contains("error[lexer]"), "{rendered}");
    assert!(rendered.contains("Lexical Error"), "{rendered}");
}

#[test]
fn compile_reports_parser_error_kind_and_filename() {
    let err = expect_compile_error_from_source(
        "mire_diag_parser_kind_filename",
        "parser_error.mire",
        "pub fn main: () {\n    set x = 10\n    if x > 5\n        use dasu(\"hola\")\n}\n",
    );

    assert!(matches!(err.kind, ErrorKind::Parser { .. }));
    assert!(
        err.filename()
            .as_deref()
            .is_some_and(|name| name.ends_with("parser_error.mire"))
    );
    let rendered = err.to_string();
    assert!(rendered.contains("error[parser]"), "{rendered}");
    assert!(rendered.contains("Syntax Error"), "{rendered}");
}

#[test]
fn compile_reports_type_error_kind_and_filename() {
    let err = expect_compile_error_from_source(
        "mire_diag_type_kind_filename",
        "type_error.mire",
        "pub fn main: () {\n    set x = 10\n    set y = \"hello\"\n    set z = x + y\n}\n",
    );

    assert!(matches!(err.kind, ErrorKind::Type { .. }));
    assert!(
        err.filename()
            .as_deref()
            .is_some_and(|name| name.ends_with("type_error.mire"))
    );
    let rendered = err.to_string();
    assert!(rendered.contains("error[type]"), "{rendered}");
    assert!(rendered.contains("Type Error"), "{rendered}");
}

#[test]
fn compile_reports_ownership_error_kind_and_filename() {
    let err = expect_compile_error_from_source(
        "mire_diag_ownership_kind_filename",
        "ownership_error.mire",
        "pub fn main: () {\n    set x = 10 :i64 mut\n    set borrowed = &x\n    set x = 20\n    use dasu(borrowed)\n}\n",
    );

    assert!(matches!(err.kind, ErrorKind::Ownership { .. }));
    assert!(
        err.filename()
            .as_deref()
            .is_some_and(|name| name.ends_with("ownership_error.mire"))
    );
    let rendered = err.to_string();
    assert!(rendered.contains("error[ownership]"), "{rendered}");
    assert!(rendered.contains("Ownership Error"), "{rendered}");
}

#[test]
fn compile_attributes_imported_type_error_to_imported_file() {
    let root = make_temp_project_root("mire_imported_type_error_filename");
    let main_path = root.join("code").join("main.mire");
    let lib_path = root.join("code").join("lib.mire");
    fs::create_dir_all(main_path.parent().expect("main parent")).expect("mkdir code");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"imported-type-error\"\nversion = \"0.1.0\"\nentry = \"code/main.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &main_path,
        "import ./code/lib\n\npub fn main: () {\n    use fail()\n}\n",
    )
    .expect("write main");
    fs::write(
        &lib_path,
        "pub fn fail: () :i64 {\n    set x = 10\n    set y = \"bad\"\n    return x + y\n}\n",
    )
    .expect("write lib");

    let err = compile_file_with_avenys(
        &main_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect_err("imported file type error should fail compilation");

    assert!(matches!(err.kind, ErrorKind::Type { .. }));
    assert!(
        err.filename()
            .as_deref()
            .is_some_and(|name| name.ends_with("code/lib.mire")),
        "{err:?}"
    );
    let rendered = err.to_string();
    assert!(rendered.contains("code/lib.mire"), "{rendered}");
    assert!(rendered.contains("Type Error"), "{rendered}");
}

#[test]
fn typed_ireru_annotation_propagates_to_let_binding() {
    let source = "pub fn main: () {\nset x = ireru(\": \") :i64\n}\n";
    let mut program = parse(source).expect("source should parse");
    check_program_types(&mut program, source).expect("type check should pass");

    let Statement::Function { body, .. } = &program.statements[0] else {
        panic!("expected function statement");
    };
    let Statement::Let {
        data_type,
        value: Some(Expression::Call {
            data_type: call_type,
            ..
        }),
        ..
    } = &body[0]
    else {
        panic!("expected typed let with call value");
    };

    assert_eq!(*data_type, DataType::I64);
    assert_eq!(*call_type, DataType::I64);
}

#[test]
fn template_output_requires_quoted_strings_for_literal_text() {
    let source = "pub fn main: () {\nset user = \"mire\"\nuse dasu(\"hola {user}\")\n}\n";
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source).expect("program should analyze");
}

#[test]
fn template_output_treats_unquoted_text_as_regular_expressions() {
    let source = "pub fn main: () {\nuse dasu(hola mundo)\n}\n";
    let mut program = parse(source).expect("regular expressions should still parse");
    let err = analyze_program(&mut program, source)
        .expect_err("unquoted text should now fail as unresolved identifiers")
        .to_string();
    assert!(err.contains("Unknown identifier 'hola'"), "{err}");
}

#[test]
fn template_output_interpolates_inside_quoted_strings() {
    let program = parse("pub fn main: () {\nset user = \"mire\"\nuse dasu(\"hola {user}!\" )\n}\n")
        .expect("source should parse");

    let Statement::Function { body, .. } = &program.statements[0] else {
        panic!("expected function statement");
    };
    let Statement::Expression(Expression::Call { name, args, .. }) = &body[1] else {
        panic!("expected dasu call");
    };

    assert_eq!(name, "dasu");
    assert!(
        contains_call_named(&args[0], "str"),
        "expected interpolation to compile to str(...) call, got {:?}",
        args[0]
    );
}

#[test]
fn match_pattern_binding_is_available_to_template_output() {
    let source = "enum Result {\n    Ok(value :i64)\n}\n\npub fn main: () {\n    set result = Result.Ok(42)\n    match result {\n        Result.Ok(v) {\n            use dasu(v)\n            set copy = v :i64\n        }\n    }\n}\n";
    let mut program = parse(source).expect("source should parse");

    analyze_program(&mut program, source).expect("match payload binding should analyze");

    let Statement::Function { body, .. } = &program.statements[1] else {
        panic!("expected function statement");
    };
    let Statement::Match { cases, .. } = &body[1] else {
        panic!("expected match statement");
    };
    let Statement::Expression(Expression::Call { args, .. }) = &cases[0].1[0] else {
        panic!("expected dasu call");
    };

    assert!(
        matches!(args.first(), Some(Expression::Identifier(_))),
        "{args:?}"
    );
}

#[test]
fn enum_variant_payload_arity_is_checked_for_direct_construction() {
    let err = expect_analysis_error(
        "enum Pair {\n    Pair(left :i64 right :i64)\n}\n\npub fn main: () {\n    set pair = Pair.Pair(10)\n}\n",
    );

    assert!(err.contains("expects 2 values, got 1"), "{err}");
}

#[test]
fn enum_variant_named_payloads_are_reordered_by_declared_field_names() {
    let root = make_temp_project_root("mire_enum_variant_named_payloads");
    let source_path = root.join("enum_variant_named_payloads.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-variant-named-payloads\"\nversion = \"0.1.0\"\nentry = \"enum_variant_named_payloads.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Status {\n    Loading(progress :i64 total :i64)\n}\n\npub fn main: () {\n    set loading = Status.Loading(total: 100, progress: 75)\n    match loading {\n        Status.Loading(progress total) {\n            use dasu(\"{progress} {total}\")\n        }\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("named enum payloads should compile");
}

#[test]
fn enum_variant_named_payloads_reject_mixed_argument_styles() {
    let err = expect_analysis_error(
        "enum Status {\n    Loading(progress :i64 total :i64)\n}\n\npub fn main: () {\n    set loading = Status.Loading(progress: 75 100)\n}\n",
    );

    assert!(
        err.contains("cannot mix named and positional arguments"),
        "{err}"
    );
}

#[test]
fn enum_variant_named_payloads_reject_unknown_fields() {
    let err = expect_analysis_error(
        "enum Status {\n    Loading(progress :i64 total :i64)\n}\n\npub fn main: () {\n    set loading = Status.Loading(percent: 75, total: 100)\n}\n",
    );

    assert!(err.contains("has no field 'percent'"), "{err}");
}

#[test]
fn enum_variant_named_payloads_reject_duplicate_fields() {
    let err = expect_analysis_error(
        "enum Status {\n    Loading(progress :i64 total :i64)\n}\n\npub fn main: () {\n    set loading = Status.Loading(progress: 75, progress: 80)\n}\n",
    );

    assert!(err.contains("received duplicate field 'progress'"), "{err}");
}

#[test]
fn match_pattern_identifier_is_not_type_checked() {
    let source =
        "pub fn main: () {\nset x = 1\nset y = match x { missing { 10 } _ { 0 } } :i64\n}\n";
    let mut program = parse(source).expect("source should parse");

    analyze_program(&mut program, source)
        .expect("match patterns should be skipped during analysis");
}

#[test]
fn match_result_identifier_still_must_resolve() {
    let err = expect_analysis_error(
        "pub fn main: () {\nset x = 1\nset y = match x { 1 { missing } _ { 0 } } :i64\n}\n",
    );

    assert!(err.contains("Unknown identifier 'missing'"), "{err}");
}

#[test]
fn if_expression_infers_branch_type_and_runs() {
    let source = "pub fn main: () {\n    set flag = true :bool\n    set result = if flag { 10 } else { 20 }\n    use dasu(result)\n}\n";
    let mut program = parse(source).expect("source should parse");

    check_program_types(&mut program, source).expect("if expression should infer branch type");

    let Statement::Function { body, .. } = &program.statements[0] else {
        panic!("expected function statement");
    };
    let Statement::Let { data_type, .. } = &body[1] else {
        panic!("expected let statement for if expression");
    };
    assert_eq!(*data_type, DataType::I64);

    let root = make_temp_project_root("mire_if_expression_infers_branch_type");
    let source_path = root.join("if_expression_infers_branch_type.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"if-expression-infers-branch-type\"\nversion = \"0.1.0\"\nentry = \"if_expression_infers_branch_type.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("if expression should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("10"), "{stdout}");
}

#[test]
fn if_expression_rejects_incompatible_branch_types() {
    let err = expect_analysis_error(
        "struct Point {\n    x :i64\n}\n\nstruct Size {\n    x :i64\n}\n\npub fn main: () {\n    set flag = true :bool\n    set value = if flag { (Point x: 1) } else { (Size x: 1) }\n    use dasu(value.x)\n}\n",
    );

    assert!(
        err.contains("Cannot unify incompatible struct types"),
        "{err}"
    );
}

#[test]
fn match_expression_with_default_infers_string_branch_type_and_compiles() {
    let source = "pub fn main: () {\n    set result = 2 :i64\n    set msg = match result {\n        1 { \"success\" }\n        _ { \"failed\" }\n    } :str\n    use dasu(msg)\n}\n";
    let mut program = parse(source).expect("source should parse");

    check_program_types(&mut program, source).expect("match expression should infer string type");

    let Statement::Function { body, .. } = &program.statements[0] else {
        panic!("expected function statement");
    };
    let Statement::Let {
        value: Some(Expression::Match { data_type, .. }),
        ..
    } = &body[1]
    else {
        panic!("expected let binding with match expression");
    };
    assert_eq!(*data_type, DataType::Str);

    let root = make_temp_project_root("mire_match_expression_default_infers_string_type");
    let source_path = root.join("match_expression_default_infers_string_type.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"match-expression-default-infers-string-type\"\nversion = \"0.1.0\"\nentry = \"match_expression_default_infers_string_type.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("match expression returning string should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("failed"), "{stdout}");
}

#[test]
fn match_expression_can_be_returned_directly_from_function() {
    let source = "pub fn classify: (x :i64) :i64 {\n    return match x {\n        1 { 10 }\n        _ { 20 }\n    } :i64\n}\n\npub fn main: () {\n    use dasu(classify(1))\n}\n";
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source).expect("return match should analyze");

    let root = make_temp_project_root("mire_return_match_direct");
    let source_path = root.join("return_match_direct.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"return-match-direct\"\nversion = \"0.1.0\"\nentry = \"return_match_direct.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("return match should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("10"), "{stdout}");
}

#[test]
fn enum_match_without_default_returns_second_variant_string() {
    let root = make_temp_project_root("mire_enum_match_second_variant_string");
    let source_path = root.join("enum_match_second_variant_string.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-second-variant-string\"\nversion = \"0.1.0\"\nentry = \"enum_match_second_variant_string.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Status {\n    Ok\n    Error\n}\n\npub fn main: () {\n    set r = Status.Error\n    set m = match r {\n        Status.Ok { \"success\" }\n        Status.Error { \"failed\" }\n    } :str\n    use dasu(m)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Release,
            opt_level: OptLevel::O3,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("enum match returning second variant string should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("failed"), "{stdout}");
}

#[test]
fn incremental_recompile_keeps_enum_match_string_result_consistent() {
    let root = make_temp_project_root("mire_enum_match_string_flip");
    let source_path = root.join("main.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-string-flip\"\nversion = \"0.1.0\"\nentry = \"main.mire\"\n[cache]\nanalysis_cache = true\ncompression = false\n",
    )
    .expect("write project");

    let run_case = |source: &str| -> String {
        fs::write(&source_path, source).expect("write source");
        let build = compile_file_with_avenys(
            &source_path,
            &BuildOptions {
                mode: BuildMode::Release,
            opt_level: OptLevel::O3,
                debug_dump: false,
                output: None,
                emit_binary: true,
                persist_ir: false,
                cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
        )
        .expect("compile case");

        let output = Command::new(&build.binary_path)
            .output()
            .expect("run binary");
        assert!(output.status.success(), "binary should run successfully");
        String::from_utf8_lossy(&output.stdout).trim().to_string()
    };

    let failed_case = "enum Status {\n    Ok\n    Error\n}\n\npub fn main: () {\n    set r = Status.Error\n    set m = match r {\n        Status.Ok { \"success\" }\n        Status.Error { \"failed\" }\n    } :str\n    use dasu(m)\n}\n";
    let error_case = "enum Status {\n    Ok\n    Error\n}\n\npub fn main: () {\n    set r = Status.Error\n    set m = match r {\n        Status.Ok { \"ok\" }\n        Status.Error { \"error\" }\n    } :str\n    use dasu(m)\n}\n";

    assert_eq!(run_case(failed_case), "failed");
    assert_eq!(run_case(error_case), "error");
    assert_eq!(run_case(failed_case), "failed");
}

#[test]
fn instance_method_call_resolves_and_compiles() {
    let source = "struct Point {\n    x :i64\n    y :i64\n}\n\nimpl Point {\n    fn distance: (self) :i64 {\n        return self.x\n    }\n}\n\npub fn main: () {\n    set p = (Point x: 3, y: 4)\n    set d = p.distance()\n    use dasu(d)\n}\n";
    let mut program = parse(source).expect("source should parse");

    analyze_program(&mut program, source).expect("instance method call should analyze");

    let Statement::Function { body, .. } = &program.statements[2] else {
        panic!("expected main function");
    };
    let Statement::Let {
        data_type,
        value:
            Some(Expression::Call {
                name,
                data_type: call_type,
                ..
            }),
        ..
    } = &body[1]
    else {
        panic!("expected method call let binding");
    };

    assert_eq!(name, "p.distance");
    assert_eq!(*data_type, DataType::I64);
    assert_eq!(*call_type, DataType::I64);

    let root = make_temp_project_root("mire_instance_method_call");
    let source_path = root.join("instance_method_call.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"instance-method-call\"\nversion = \"0.1.0\"\nentry = \"instance_method_call.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("instance method call should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains('3'), "{stdout}");
}

#[test]
fn direct_template_member_access_prints_field_values() {
    let root = make_temp_project_root("mire_direct_template_member_access");
    let source_path = root.join("direct_template_member_access.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"direct-template-member-access\"\nversion = \"0.1.0\"\nentry = \"direct_template_member_access.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "struct Person {\n    name :str\n    age :i64\n}\n\npub fn main: () {\n    set person = (Person name: \"Alice\", age: 30)\n    use dasu(person.age)\n    use dasu(person.name)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("member access template should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("30"), "{stdout}");
    assert!(stdout.contains("Alice"), "{stdout}");
    assert!(!stdout.contains(". age"), "{stdout}");
    assert!(!stdout.contains(". name"), "{stdout}");
}

#[test]
fn direct_struct_field_assignment_updates_mutable_binding() {
    let source = "struct Counter {\n    value :i64\n}\n\npub fn main: () {\n    set counter = (Counter value: 10) mut\n    set counter.value = 41\n    set counter.value = counter.value + 1\n    use dasu(counter.value)\n}\n";
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source).expect("field assignment should analyze");

    let root = make_temp_project_root("mire_direct_struct_field_assignment");
    let source_path = root.join("direct_struct_field_assignment.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"direct-struct-field-assignment\"\nversion = \"0.1.0\"\nentry = \"direct_struct_field_assignment.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("field assignment should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("42"), "{stdout}");
}

#[test]
fn immutable_struct_field_assignment_still_errors() {
    let err = expect_analysis_error(
        "struct Counter {\n    value :i64\n}\n\npub fn main: () {\n    set counter = (Counter value: 10)\n    set counter.value = 11\n}\n",
    );

    assert!(
        err.contains("Cannot reassign immutable variable 'counter.value'")
            || err.contains("Cannot reassign immutable variable 'counter'"),
        "{err}"
    );
}

#[test]
fn struct_with_array_field_declaration_and_construction_compiles() {
    let source = "struct Stack {\n    items :arr[i64 3]\n    size :i64\n}\n\npub fn main: () {\n    set stack = (Stack items: [1 2 3] :arr[i64 3], size: 3)\n    use dasu(stack.size)\n}\n";
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source).expect("struct array field should analyze");

    let root = make_temp_project_root("mire_struct_array_field");
    let source_path = root.join("struct_array_field.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"struct-array-field\"\nversion = \"0.1.0\"\nentry = \"struct_array_field.mire\"\n",
    )
    .expect("write project");
    fs::write(&source_path, source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("struct array field should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("3"), "{stdout}");
}

#[test]
fn static_impl_method_call_resolves_and_runs() {
    let root = make_temp_project_root("mire_static_impl_method_call");
    let source_path = root.join("static_impl_method_call.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"static-impl-method-call\"\nversion = \"0.1.0\"\nentry = \"static_impl_method_call.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "struct Point {\n    x :i64\n    y :i64\n}\n\nimpl Point {\n    fn new: (x :i64 y :i64) :Point {\n        return (Point x: x, y: y)\n    }\n}\n\npub fn main: () {\n    set p = Point::new(10 20)\n    use dasu(p.x)\n    use dasu(p.y)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("static impl method call should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("10"), "{stdout}");
    assert!(stdout.contains("20"), "{stdout}");
}

#[test]
fn implicit_self_method_return_still_runs() {
    let root = make_temp_project_root("mire_explicit_self_method_return");
    let source_path = root.join("explicit_self_method_return.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"explicit-self-method-return\"\nversion = \"0.1.0\"\nentry = \"explicit_self_method_return.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "struct Person {\n    name :str\n    age :i64\n}\n\nimpl Person {\n    fn get_name: (self) :str {\n        return self.name\n    }\n\n    fn get_age: (self) :i64 {\n        return self.age\n    }\n}\n\npub fn main: () {\n    set person = (Person name: \"Alice\", age: 25)\n    use dasu(person.get_name())\n    use dasu(person.get_age())\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("explicit self method return should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Alice"), "{stdout}");
    assert!(stdout.contains("25"), "{stdout}");
}

#[test]
fn method_using_self_without_explicit_self_is_rejected() {
    let source = "struct Person {\n    age :i64\n}\n\nimpl Person {\n    fn get_age: () :i64 {\n        return self.age\n    }\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source)
        .expect_err("program should fail type checking")
        .to_string();

    assert!(err.contains("Unknown identifier 'self'"), "{err}");
}

#[test]
fn distinct_struct_types_do_not_unify_by_shape() {
    let source = "struct Point {\n    x :i64\n}\n\nstruct Size {\n    x :i64\n}\n\nfn needs_size: (value :Size) :i64 {\n    return value.x\n}\n\npub fn main: () {\n    set point = (Point x: 1)\n    use dasu(needs_size(point))\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source)
        .expect_err("distinct nominal struct types must not unify")
        .to_string();

    assert!(err.contains("expects StructNamed(\"Size\")"), "{err}");
    assert!(err.contains("got StructNamed(\"Point\")"), "{err}");
}

#[test]
fn trait_self_type_accepts_owner_nominal_type_in_impl() {
    let source = "struct Point {\n    x :i64\n}\n\npub skill Projectable {\n    fn project: (self: Point) :i64\n}\n\nimpl Projectable for Point {\n    fn project: (self) :i64 {\n        return self.x\n    }\n}\n\npub fn main: () {\n    set point = (Point x: 7)\n    use dasu(point.project())\n}\n";
    let mut program = parse(source).expect("source should parse");

    analyze_program(&mut program, source)
        .expect("trait self type should resolve to the impl owner nominal type");
}

#[test]
fn trait_instance_method_cannot_be_implemented_as_associated() {
    let err = expect_analysis_error(
        "struct Point {\n    x :i64\n}\n\npub skill Projectable {\n    fn project: (self) :i64\n}\n\nimpl Projectable for Point {\n    fn project: () :i64 {\n        return 0\n    }\n}\n",
    );

    assert!(
        err.contains("must be implemented as an instance method"),
        "{err}"
    );
}

#[test]
fn trait_associated_method_cannot_be_implemented_as_instance() {
    let err = expect_analysis_error(
        "struct Point {\n    x :i64\n}\n\npub skill Factory {\n    fn build: () :Point\n}\n\nimpl Factory for Point {\n    fn build: (self) :Point {\n        return self\n    }\n}\n",
    );

    assert!(
        err.contains("must be implemented as an associated method"),
        "{err}"
    );
}

#[test]
fn impl_self_parameter_must_be_first() {
    let err = expect_analysis_error(
        "struct Point {\n    x :i64\n}\n\nimpl Point {\n    fn bad: (value :i64 self) :i64 {\n        return value\n    }\n}\n",
    );

    assert!(
        err.contains("Method 'Point.bad' must declare 'self' as the first parameter"),
        "{err}"
    );
}

#[test]
fn empty_skill_is_rejected() {
    let err = expect_analysis_error(
        "import std\n\npub skill Printable {\n}\n\npub fn main: () {\n    use dasu(\"test\")\n}\n",
    );

    assert!(
        err.contains("Skill 'Printable' must declare at least one method"),
        "{err}"
    );
}

#[test]
fn runtime_division_by_zero_exits_with_error() {
    let root = make_temp_project_root("mire_runtime_division_by_zero");
    let source_path = root.join("runtime_division_by_zero.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"runtime-division-by-zero\"\nversion = \"0.1.0\"\nentry = \"runtime_division_by_zero.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set x = 10 / 0\n    use dasu(x)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(!output.status.success(), "binary should fail at runtime");
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("division by zero"), "{stderr}");
}

#[test]
fn signed_integer_division_and_remainder_match_runtime_expectations() {
    let root = make_temp_project_root("mire_signed_division");
    let source_path = root.join("signed_division.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"signed-division\"\nversion = \"0.1.0\"\nentry = \"signed_division.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set a = -10 / 3\n    set b = -10 % 3\n    use dasu(\"{a} {b}\")\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "{output:?}");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("-3 -1"), "{stdout}");
}

#[test]
fn float_arithmetic_with_typed_float_variable_executes() {
    let root = make_temp_project_root("mire_float_arithmetic_typed_var");
    let source_path = root.join("float_arithmetic_typed_var.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"float-arithmetic-typed-var\"\nversion = \"0.1.0\"\nentry = \"float_arithmetic_typed_var.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set x = 2.0 :f64\n    set y = x + 1.5\n    set z = y * 2.0\n    use dasu(z > 6.9 && z < 7.1)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("float arithmetic should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("true"), "{stdout}");
}

#[test]
fn nested_vector_type_is_preserved_for_lists_push() {
    let err = expect_analysis_error(
        "import std\n\npub fn main: () {\n    set nested = [[1 2] [3 4]] :vec[vec[i64]]\n    set bad = lists.push(nested [\"x\"])\n    use dasu(bad)\n}\n",
    );

    assert!(
        err.contains("Cannot unify incompatible types")
            || err.contains("Type mismatch")
            || err.contains("expects vec"),
        "{err}"
    );
}

#[test]
fn secondary_for_loop_binding_compiles_and_uses_index() {
    let root = make_temp_project_root("mire_for_secondary_binding");
    let source_path = root.join("for_secondary_binding.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"for-secondary-binding\"\nversion = \"0.1.0\"\nentry = \"for_secondary_binding.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set acc = 0 :i64 mut\n    for item, index in range(4) {\n        set acc = acc + item + index\n    }\n    use dasu(acc)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("two-binding for loop should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("12"), "{stdout}");
}

#[test]
fn advanced_literals_compile_and_run() {
    let root = make_temp_project_root("mire_advanced_literals");
    let source_path = root.join("advanced_literals.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"advanced-literals\"\nversion = \"0.1.0\"\nentry = \"advanced_literals.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set bin = 0b1010 :i64\n    set oct = 0o12 :i64\n    set hex = 0xFF :i64\n    set c = 'a' :char\n    set newline = '\\n' :char\n    set raw = r##\"hello \"world\" with ##\"## :str\n    use dasu(bin == oct && hex == 255)\n    use dasu(c == 97 && newline == 10)\n    use dasu(raw)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("advanced literals should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("true"), "{stdout}");
    assert!(stdout.contains("hello \"world\" with ##"), "{stdout}");
}

#[test]
fn unsafe_block_compiles_and_runs() {
    let root = make_temp_project_root("mire_unsafe_block");
    let source_path = root.join("unsafe_block.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"unsafe-block\"\nversion = \"0.1.0\"\nentry = \"unsafe_block.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set sum = 0 :i64 mut\n    unsafe {\n        set sum = sum + 2\n    }\n    use dasu(sum)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("unsafe block should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("2"), "{stdout}");
}

#[test]
fn extern_and_inline_asm_declarations_parse_and_compile() {
    let root = make_temp_project_root("mire_extern_asm_parse_compile");
    let source_path = root.join("extern_asm_parse_compile.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"extern-asm-parse-compile\"\nversion = \"0.1.0\"\nentry = \"extern_asm_parse_compile.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\nextern lib \"c\" \"libc.so.6\"\nextern fn puts: (msg :*const i8) :i32 lib \"c\"\n\npub fn main: () {\n    asm {\n        nop\n        nop\n    }\n    use dasu(\"ok\")\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("extern/asm declarations should compile");
}

#[test]
fn runtime_out_of_bounds_exits_with_error() {
    let root = make_temp_project_root("mire_runtime_out_of_bounds");
    let source_path = root.join("runtime_out_of_bounds.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"runtime-out-of-bounds\"\nversion = \"0.1.0\"\nentry = \"runtime_out_of_bounds.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set nums = [1 2 3] :arr[i64 3]\n    set x = nums at 10\n    use dasu(x)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(!output.status.success(), "binary should fail at runtime");
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("index out of bounds"), "{stderr}");
}

#[test]
fn backend_rejects_unimplemented_contains_instead_of_returning_silent_false() {
    let err = expect_compile_error_from_source(
        "mire_backend_contains_stub",
        "contains_stub.mire",
        "import std\n\npub fn main: () {\n    set nums = [1 2 3]\n    use dasu(contains(nums 2))\n}\n",
    );

    assert!(matches!(err.kind, ErrorKind::Backend { .. }));
    assert!(err.to_string().contains("contains"), "{err}");
}

#[test]
fn strings_split_returns_list_and_works_with_join() {
    let root = make_temp_project_root("mire_strings_split");
    let source_path = root.join("strings_split.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"strings-split\"\nversion = \"0.1.0\"\nentry = \"strings_split.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set parts = strings.split(\"a,b,c\" \",\")\n    set joined = strings.join(parts \"-\")\n    use dasu(joined)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("strings.split should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("a-b-c"), "Expected 'a-b-c', got: {stdout}");
}

#[test]
fn strings_split_supports_multi_char_delimiter() {
    let root = make_temp_project_root("mire_strings_split_multichar");
    let source_path = root.join("strings_split_multichar.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"strings-split-multichar\"\nversion = \"0.1.0\"\nentry = \"strings_split_multichar.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set parts = strings.split(\"alpha--beta--gamma\" \"--\")\n    use dasu(strings.join(parts \"|\"))\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("strings.split multichar should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains("alpha|beta|gamma"),
        "Expected 'alpha|beta|gamma', got: {stdout}"
    );
}

#[test]
fn strings_split_preserves_empty_segments() {
    let root = make_temp_project_root("mire_strings_split_empty_segments");
    let source_path = root.join("strings_split_empty_segments.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"strings-split-empty\"\nversion = \"0.1.0\"\nentry = \"strings_split_empty_segments.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set parts = strings.split(\"a,,b,\" \",\")\n    use dasu(strings.join(parts \"|\"))\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("strings.split empty segments should compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should run successfully");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("a||b|"), "Expected 'a||b|', got: {stdout}");
}

#[test]
fn syntax_reference_prototype_compiles_and_runs() {
    let root = make_temp_project_root("mire_syntax_prototype");
    let source_path = root.join("prototype.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"syntax-prototype\"\nversion = \"0.1.0\"\nentry = \"prototype.mire\"\n",
    )
    .expect("write project");
    let prototype_source = fs::read_to_string("tests/syntax/prototype.mire")
        .expect("read syntax prototype source");
    fs::write(&source_path, prototype_source).expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("syntax prototype should compile");

    let output = Command::new(&build.binary_path)
        .current_dir(&root)
        .output()
        .expect("run binary");
    assert!(output.status.success(), "{output:?}");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("a|b|c"), "{stdout:?}");
    assert!(stdout.contains("child"), "{stdout:?}");
}

#[test]
fn array_index_assignment_mutates_elements_in_place() {
    let root = make_temp_project_root("mire_array_index_assignment");
    let source_path = root.join("array_index_assignment.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"array-index-assignment\"\nversion = \"0.1.0\"\nentry = \"array_index_assignment.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\nfn swap_edges: (arr :arr[i64 4]) {\n    set left = arr at 0\n    set right = arr at 3\n    set arr at 0 = right\n    set arr at 3 = left\n}\n\npub fn main: () {\n    set arr = [10 20 30 40] :arr[i64 4]\n    swap_edges(arr)\n    use dasu(\"{arr at 0} {arr at 1} {arr at 2} {arr at 3}\")\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should succeed");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("40 20 30 10"), "{stdout}");
}

#[test]
fn struct_array_field_index_assignment_compiles_and_runs() {
    let root = make_temp_project_root("mire_struct_array_index_assignment");
    let source_path = root.join("struct_array_index_assignment.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"struct-array-index-assignment\"\nversion = \"0.1.0\"\nentry = \"struct_array_index_assignment.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\nstruct Matrix {\n    data :arr[i64 4]\n    cols :i64\n}\n\nimpl Matrix {\n    fn new: () :Matrix {\n        return (Matrix data: [0 0 0 0] :arr[i64 4], cols: 2)\n    }\n\n    fn update: (self row :i64 col :i64 val :i64) {\n        set idx = row * self.cols + col\n        set self.data at idx = val\n    }\n\n    fn get: (self row :i64 col :i64) :i64 {\n        set idx = row * self.cols + col\n        return self.data at idx\n    }\n}\n\npub fn main: () {\n    set m = Matrix::new()\n    m.update(0 1 7)\n    m.update(1 0 9)\n    use dasu(\"{m.get(0 1)} {m.get(1 0)}\")\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should succeed");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("7 9"), "{stdout}");
}

#[test]
fn shared_reference_lowering_compiles_and_runs() {
    let root = make_temp_project_root("mire_shared_reference_lowering");
    let source_path = root.join("shared_reference_lowering.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"shared-reference-lowering\"\nversion = \"0.1.0\"\nentry = \"shared_reference_lowering.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\nfn read_ref: (value :&i64) :i64 {\n    return *value\n}\n\npub fn main: () {\n    set x = 41 :i64\n    set rx = &x\n    set y = read_ref(rx)\n    use dasu(y + 1)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should succeed");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("42"), "{stdout}");
}

#[test]
fn impl_method_can_mutate_self_field_and_run() {
    let root = make_temp_project_root("mire_impl_self_field_mutation");
    let source_path = root.join("impl_self_field_mutation.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"impl-self-field-mutation\"\nversion = \"0.1.0\"\nentry = \"impl_self_field_mutation.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\nstruct Counter {\n    value :i64 mut\n    step :i64\n}\n\nimpl Counter {\n    fn new: (step :i64) :Counter {\n        return (Counter value: 0, step: step)\n    }\n\n    fn increment: (self) {\n        set self.value = self.value + self.step\n    }\n\n    fn reset: (self) {\n        set self.value = 0\n    }\n\n    fn get: (self) :i64 {\n        return self.value\n    }\n}\n\npub fn main: () {\n    set c = Counter::new(5)\n    c.increment()\n    c.increment()\n    c.reset()\n    c.increment()\n    use dasu(c.get())\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("compile");

    let output = Command::new(&build.binary_path)
        .output()
        .expect("run binary");

    assert!(output.status.success(), "binary should succeed");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("5"), "{stdout}");
}

#[test]
fn impl_method_self_field_assignment_typechecks() {
    let source = "struct Counter {\n    value :i64 mut\n    step :i64\n}\n\nimpl Counter {\n    fn increment: (self) {\n        set self.value = self.value + self.step\n    }\n}\n";
    let mut program = parse(source).expect("source should parse");
    check_program_types(&mut program, source).expect("source should typecheck");
}

#[test]
fn impl_method_self_field_assignment_parses() {
    let source = "struct Counter {\n    value :i64 mut\n    step :i64\n}\n\nimpl Counter {\n    fn increment: (self) {\n        set self.value = self.value + self.step\n    }\n}\n";
    let program = parse(source).expect("source should parse");
    assert_eq!(program.statements.len(), 2);
}

#[test]
fn impl_method_empty_body_parses() {
    let source = "struct Counter {\n    value :i64 mut\n}\n\nimpl Counter {\n    fn increment: (self) {\n    }\n}\n";
    let program = parse(source).expect("source should parse");
    assert_eq!(program.statements.len(), 2);
}

#[test]
fn impl_method_local_assignment_parses() {
    let source = "struct Counter {\n    value :i64 mut\n}\n\nimpl Counter {\n    fn increment: (self) {\n        set x = 1\n    }\n}\n";
    let program = parse(source).expect("source should parse");
    assert_eq!(program.statements.len(), 2);
}

#[test]
fn parses_local_import_with_selection() {
    let program = parse("import ./utils: (helper value)\n").expect("source should parse");
    let Statement::Use {
        path,
        items,
        is_local,
        ..
    } = &program.statements[0]
    else {
        panic!("expected use statement");
    };

    assert_eq!(path, "./utils");
    assert_eq!(
        items.as_ref().expect("selected items"),
        &vec!["helper".to_string(), "value".to_string()]
    );
    assert!(*is_local);
}

#[test]
fn local_import_loads_selected_symbols_from_project_root() {
    let root = make_temp_project_root("mire_local_import");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"local-import\"\nversion = \"0.1.0\"\nentry = \"code/main.mire\"\n",
    )
    .expect("write project");
    fs::create_dir_all(root.join("code")).expect("mkdir code");
    fs::write(
        root.join("code").join("helpers.mire"),
        "pub fn helper: () {\n    use dasu(\"ok\")\n}\n\npub fn ignored: () {\n    use dasu(\"no\")\n}\n",
    )
    .expect("write helpers");
    let main_path = root.join("code").join("main.mire");
    fs::write(
        &main_path,
        "import ./code/helpers: (helper)\n\npub fn main: () {\n    use helper()\n}\n",
    )
    .expect("write main");

    let mut program = load_program_from_file(&main_path).expect("load program");
    let source = fs::read_to_string(&main_path).expect("read source");
    analyze_program(&mut program, &source).expect("expanded program should analyze");

    let exported_names: Vec<String> = program
        .statements
        .iter()
        .filter_map(|statement| match statement {
            Statement::Function { name, .. } => Some(name.clone()),
            _ => None,
        })
        .collect();

    assert!(exported_names.contains(&"helper".to_string()));
    assert!(exported_names.contains(&"main".to_string()));
    assert!(!exported_names.contains(&"ignored".to_string()));
}

#[test]
fn local_import_requires_project_root() {
    let root = unique_temp_dir("mire_local_import_no_root");
    fs::create_dir_all(&root).expect("mkdir root");
    let main_path = root.join("main.mire");
    fs::write(
        &main_path,
        "import ./helpers: (helper)\n\npub fn main: () {\n    use helper()\n}\n",
    )
    .expect("write main");
    fs::write(
        root.join("helpers.mire"),
        "pub fn helper: () {\n    use dasu(\"ok\")\n}\n",
    )
    .expect("write helper");

    let err = load_program_from_file(&main_path).expect_err("must require project root");
    assert!(
        err.to_string().contains("require a Mire project root"),
        "{err}"
    );
}

#[test]
fn pipeline_self_placeholder_analyzes_after_desugaring() {
    let source = "import std\npub fn main: () {\nuse range(5) => dasu(self)\n}\n";
    let mut program = parse(source).expect("source should parse");

    analyze_program(&mut program, source).expect("pipeline self placeholder should analyze");
}

#[test]
fn enum_match_payload_statement_body_compiles() {
    let root = make_temp_project_root("mire_enum_match_payload");
    let source_path = root.join("enum_match_payload.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-payload\"\nversion = \"0.1.0\"\nentry = \"enum_match_payload.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Result {\n    Ok(value :i64)\n    Err(err_num :i64)\n}\n\npub fn main: () {\n    set result = Result.Ok(42)\n    match result {\n        Result.Ok(v) {\n            use dasu(v)\n            set copy = v :i64\n        }\n        Result.Err(err_num) {\n            use dasu(err_num)\n        }\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("enum match payload statement body should compile");
}

#[test]
fn enum_match_multiple_payloads_compile() {
    let root = make_temp_project_root("mire_enum_match_multi_payload");
    let source_path = root.join("enum_match_multi_payload.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-multi-payload\"\nversion = \"0.1.0\"\nentry = \"enum_match_multi_payload.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Pair {\n    Pair(left :i64 right :i64)\n    Empty\n}\n\npub fn main: () {\n    set pair = Pair.Pair(10 20)\n    match pair {\n        Pair.Pair(a b) {\n            use dasu(\"{a} {b}\")\n            set total = a + b :i64\n            use dasu(total)\n        }\n        Pair.Empty {\n            use dasu(\"empty\")\n        }\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("enum match with multiple payloads should compile");
}

#[test]
fn enum_declaration_with_comma_separated_payloads_compiles() {
    let root = make_temp_project_root("mire_enum_match_multi_payload_commas");
    let source_path = root.join("enum_match_multi_payload_commas.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-multi-payload-commas\"\nversion = \"0.1.0\"\nentry = \"enum_match_multi_payload_commas.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Color {\n    Custom(r :i64, g :i64, b :i64)\n}\n\npub fn main: () {\n    set color = Color.Custom(10 20 30)\n    match color {\n        Color.Custom(r g b) {\n            use dasu(\"{r} {g} {b}\")\n        }\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("comma-separated enum payloads should compile");
}

#[test]
fn enum_match_statement_payload_bindings_support_string_and_bool() {
    let root = make_temp_project_root("mire_enum_match_statement_payload_types");
    let source_path = root.join("enum_match_statement_payload_types.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"enum-match-statement-payload-types\"\nversion = \"0.1.0\"\nentry = \"enum_match_statement_payload_types.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "enum Response {\n    Ok(message :str retry :bool)\n    Empty\n}\n\npub fn main: () {\n    set response = Response.Ok(\"ready\" true)\n    match response {\n        Response.Ok(message retry) {\n            use dasu(message)\n            if retry {\n                use dasu(\"retrying\")\n            }\n            set copy = message :str\n            use dasu(copy)\n        }\n        Response.Empty {\n            use dasu(\"empty\")\n        }\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("match statement payload bindings should support string and bool");
}

#[test]
fn pipeline_len_builtin_compiles() {
    let root = make_temp_project_root("mire_pipeline_len");
    let source_path = root.join("pipeline_len.mire");
    fs::write(
        &source_path,
        "import std\npub fn main: () {\nset x = [1 2 3] :arr[i64 3]\nset y = x => len()\nuse dasu(\"y: {y}\")\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("pipeline len should compile");
}

#[test]
fn nested_output_pipeline_compiles() {
    let root = make_temp_project_root("mire_pipeline_nested_output");
    let source_path = root.join("nested_output.mire");
    fs::write(
        &source_path,
        "import std\npub fn main: () {\nuse dasu(\"Hello\") => use dasu(self)\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("nested output pipeline should compile");
}

#[test]
fn find_statement_compiles_and_lowers() {
    let root = make_temp_project_root("mire_find_statement");
    let source_path = root.join("find_statement.mire");
    fs::write(
        &source_path,
        "import std\npub fn main: () {\n    find item in [1 2 3] {\n        use dasu(item)\n    }\n}\n",
    )
    .expect("write source");

    compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("find statement should compile and lower");
}

#[test]
fn bindings_const_and_compound_assignment_analyze() {
    let source = "pub fn main: () {\n    set base = 10 :i64 const\n    set acc = 5 :i64 mut\n    set acc += base\n    set acc -= 1\n    set acc *= 2\n    set acc /= 2\n    set acc %= 3\n    use dasu(acc)\n}\n";
    let mut program = parse(source).expect("source should parse");
    analyze_program(&mut program, source).expect("const + compound assignment should analyze");
}

#[test]
fn debug_build_persists_ir_on_disk() {
    let root = make_temp_project_root("mire_debug_persists_ir");
    let source_path = root.join("debug_ir.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"debug-ir\"\nversion = \"0.1.0\"\nentry = \"debug_ir.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\npub fn main: () {\n    use dasu(\"debug\")\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: true,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("debug compile");

    assert!(build.ir_path.as_ref().is_some_and(|path| path.exists()));
    assert!(
        build
            .optimized_ir_path
            .as_ref()
            .is_some_and(|path| path.exists())
    );
}

#[test]
fn incremental_loader_tracks_hashes_for_local_dependencies() {
    let root = make_temp_project_root("mire_incremental_loader");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"incremental-loader\"\nversion = \"0.1.0\"\nentry = \"code/main.mire\"\n",
    )
    .expect("write project");
    fs::create_dir_all(root.join("code")).expect("mkdir code");

    let helper_path = root.join("code").join("helper.mire");
    fs::write(
        &helper_path,
        "pub fn helper: () {\n    use dasu(\"one\")\n}\n",
    )
    .expect("write helper");
    let main_path = root.join("code").join("main.mire");
    fs::write(
        &main_path,
        "import ./code/helper: (helper)\n\npub fn main: () {\n    use helper()\n}\n",
    )
    .expect("write main");

    let first = load_program_with_metadata(&main_path).expect("load first");
    let main_hash = first
        .files
        .get(&main_path.canonicalize().expect("canonical main"))
        .expect("main metadata")
        .hash;
    let helper_hash = first
        .files
        .get(&helper_path.canonicalize().expect("canonical helper"))
        .expect("helper metadata")
        .hash;

    fs::write(
        &helper_path,
        "pub fn helper: () {\n    use dasu(\"two\")\n}\n",
    )
    .expect("rewrite helper");

    let second = load_program_with_metadata(&main_path).expect("load second");
    let second_main_hash = second
        .files
        .get(&main_path.canonicalize().expect("canonical main"))
        .expect("main metadata")
        .hash;
    let second_helper_hash = second
        .files
        .get(&helper_path.canonicalize().expect("canonical helper"))
        .expect("helper metadata")
        .hash;

    assert_eq!(main_hash, second_main_hash);
    assert_ne!(helper_hash, second_helper_hash);
    assert!(cache_file_path(&main_path).exists());
}

#[test]
fn incremental_build_reuses_artifacts_when_inputs_are_unchanged() {
    let root = make_temp_project_root("mire_incremental_build_reuse");
    let source_path = root.join("reuse.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"incremental-build\"\nversion = \"0.1.0\"\nentry = \"reuse.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\npub fn main: () {\n    use dasu(\"cache\")\n}\n",
    )
    .expect("write source");

    let first = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("first compile");
    assert!(first.ir_path.is_none());
    let bin_mtime = fs::metadata(&first.binary_path)
        .expect("bin metadata")
        .modified()
        .expect("bin modified");

    thread::sleep(Duration::from_millis(50));

    let second = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("second compile");
    assert!(second.ir_path.is_none());
    let bin_mtime_after = fs::metadata(&second.binary_path)
        .expect("bin metadata after")
        .modified()
        .expect("bin modified after");

    assert_eq!(bin_mtime, bin_mtime_after);
}

#[test]
fn incremental_build_invalidates_on_local_import_change() {
    let root = make_temp_project_root("mire_incremental_build_invalidate");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"incremental-invalidate\"\nversion = \"0.1.0\"\nentry = \"code/main.mire\"\n",
    )
    .expect("write project");
    fs::create_dir_all(root.join("code")).expect("mkdir code");

    let helper_path = root.join("code").join("helper.mire");
    fs::write(
        &helper_path,
        "pub fn helper: () {\n    use dasu(\"one\")\n}\n",
    )
    .expect("write helper");
    let main_path = root.join("code").join("main.mire");
    fs::write(
        &main_path,
        "import ./code/helper: (helper)\n\npub fn main: () {\n    use helper()\n}\n",
    )
    .expect("write main");

    let first = compile_file_with_avenys(
        &main_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("first compile");
    let bin_mtime = fs::metadata(&first.binary_path)
        .expect("bin metadata")
        .modified()
        .expect("bin modified");

    thread::sleep(Duration::from_millis(50));
    fs::write(
        &helper_path,
        "pub fn helper: () {\n    use dasu(\"two\")\n}\n",
    )
    .expect("rewrite helper");

    let second = compile_file_with_avenys(
        &main_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("second compile");
    let bin_mtime_after = fs::metadata(&second.binary_path)
        .expect("bin metadata after")
        .modified()
        .expect("bin modified after");

    assert!(bin_mtime_after > bin_mtime);
}

#[test]
fn incremental_analysis_error_is_cached_for_identical_inputs() {
    let root = make_temp_project_root("mire_incremental_analysis_error_cache");
    let source_path = root.join("broken.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"incremental-analysis-error\"\nversion = \"0.1.0\"\nentry = \"broken.mire\"\n[cache]\nmax_units = 256\nanalysis_cache = true\ncompression = false\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "pub fn main: () {\n    set x = missing_value\n}\n",
    )
    .expect("write source");

    let first = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect_err("first compile should fail");
    assert!(matches!(first.kind, ErrorKind::Type { .. }));

    let cache_path = cache_file_path(&source_path);
    assert!(cache_path.exists());

    thread::sleep(Duration::from_millis(50));

    let second = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect_err("second compile should fail");
    assert!(matches!(second.kind, ErrorKind::Type { .. }));
    assert_eq!(first.to_string(), second.to_string());
    assert!(cache_path.exists());
}

fn contains_call_named(expr: &Expression, target: &str) -> bool {
    match expr {
        Expression::Call { name, .. } => name == target,
        Expression::BinaryOp { left, right, .. } => {
            contains_call_named(left, target) || contains_call_named(right, target)
        }
        _ => false,
    }
}

#[test]
fn list_hofs_infer_closure_params_and_execute() {
    let root = make_temp_project_root("mire_list_hofs");
    let source_path = root.join("list_hofs.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"list-hofs\"\nversion = \"0.1.0\"\nentry = \"list_hofs.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set sum = lists.fold(0, (acc elem) => acc + elem, [1 2 3 4 5])\n    set doubled = lists.map((x) => x * 2, [1 2 3])\n    set filtered = lists.filter((x) => x > 2, [1 2 3 4])\n    use dasu(\"{sum} {lists.get(doubled 2)} {lists.get(filtered 1)}\")\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("list hof sample should compile");

    let output = Command::new(&build.binary_path)
        .current_dir(&root)
        .output()
        .expect("run compiled binary");
    assert!(output.status.success(), "{output:?}");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("15 6 4"), "{stdout}");
}

#[test]
fn nested_map_string_render_executes_without_runtime_errors() {
    let root = make_temp_project_root("mire_nested_map_string");
    let source_path = root.join("nested_map_string.mire");
    fs::write(
        root.join("project.toml"),
        "[project]\nname = \"nested-map-string\"\nversion = \"0.1.0\"\nentry = \"nested_map_string.mire\"\n",
    )
    .expect("write project");
    fs::write(
        &source_path,
        "import std\n\npub fn main: () {\n    set inner = {x: 1, y: 2} :map[str i64]\n    set outer = {child: inner} :map[str map[str i64]]\n    use dasu(outer)\n}\n",
    )
    .expect("write source");

    let build = compile_file_with_avenys(
        &source_path,
        &BuildOptions {
            mode: BuildMode::Debug,
            opt_level: OptLevel::O0,
            debug_dump: false,
            output: None,
            emit_binary: true,
            persist_ir: false,
            cache: Default::default(),
            warning_filter: mire::error::diagnostic::WarningFilter::Default,
            deny_warnings: std::collections::HashSet::new(),
        },
    )
    .expect("nested map sample should compile");

    let output = Command::new(&build.binary_path)
        .current_dir(&root)
        .output()
        .expect("run compiled binary");
    assert!(output.status.success(), "{output:?}");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("child"), "{stdout:?}");
    assert!(stdout.contains("x"), "{stdout:?}");
    assert!(stdout.contains("y"), "{stdout:?}");
}

#[test]
fn enum_match_statement_requires_exhaustive_coverage_without_default() {
    let source = "enum State {\n    Idle\n    Busy\n}\n\npub fn main: () {\n    set state = State.Idle\n    match state {\n        State.Idle { use dasu(\"idle\") }\n    }\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source).expect_err("typecheck should fail");
    let rendered = err.to_string();
    assert!(rendered.contains("Non-exhaustive match for enum 'State'"), "{rendered}");
}

#[test]
fn enum_match_expression_rejects_duplicate_variant_arms() {
    let source = "enum State {\n    Idle\n    Busy\n}\n\npub fn main: () {\n    set state = State.Idle\n    match state {\n        State.Idle { use dasu(1) }\n        State.Idle { use dasu(2) }\n        _ { use dasu(3) }\n    }\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source).expect_err("typecheck should fail");
    let rendered = err.to_string();
    assert!(rendered.contains("Duplicate match arm for enum variant 'State.Idle'"), "{rendered}");
}

#[test]
fn new_statement_rejects_non_collection_targets() {
    let source = "pub fn main: () {\n    new::(42) :i64\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source).expect_err("typecheck should fail");
    let rendered = err.to_string();
    assert!(
        rendered.contains("new:: only supports arr/vec/map targets"),
        "{rendered}"
    );
}

#[test]
fn own_statement_rejects_none_target() {
    let source = "pub fn main: () {\n    own::() :none\n}\n";
    let mut program = parse(source).expect("source should parse");
    let err = check_program_types(&mut program, source).expect_err("typecheck should fail");
    let rendered = err.to_string();
    assert!(
        rendered.contains("own:: target type None is not heap-allocatable"),
        "{rendered}"
    );
}

fn make_temp_project_root(prefix: &str) -> PathBuf {
    let root = unique_temp_dir(prefix);
    fs::create_dir_all(&root).expect("mkdir project root");
    root
}

fn unique_temp_dir(prefix: &str) -> PathBuf {
    let nonce = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("clock")
        .as_nanos();
    std::env::temp_dir().join(format!("{prefix}_{nonce}"))
}
