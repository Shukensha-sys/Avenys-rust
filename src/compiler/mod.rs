pub mod borrowck;
pub mod semantic;
pub mod typeck;

use crate::error::Result;
use crate::parser::Program;
use std::collections::HashMap;
use std::path::PathBuf;

pub use semantic::{
    BindingInfo, BindingKind, BorrowFact, BorrowKind, MoveFact, ScopeInfo, SemanticModel,
};
pub use typeck::check_program_types;

#[derive(Debug, Clone, Default)]
pub struct AnalysisSelection {
    pub statement_mask: Vec<bool>,
    pub nested_statement_masks: HashMap<String, Vec<bool>>,
}

impl AnalysisSelection {
    pub fn full(program: &Program) -> Self {
        Self {
            statement_mask: vec![true; program.statements.len()],
            nested_statement_masks: HashMap::new(),
        }
    }
}

pub fn analyze_program(program: &mut Program, source: &str) -> Result<SemanticModel> {
    typeck::check_program_types(program, source)?;
    let semantic_model = semantic::analyze_program(program);
    borrowck::check_program(program, &semantic_model)?;
    Ok(semantic_model)
}

pub fn analyze_program_with_origins(
    program: &mut Program,
    source: &str,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
) -> Result<SemanticModel> {
    analyze_program_with_origins_partial(
        program,
        source,
        statement_origins,
        sources,
        &AnalysisSelection::full(program),
    )
}

pub fn analyze_program_with_origins_partial(
    program: &mut Program,
    source: &str,
    statement_origins: &[PathBuf],
    sources: &HashMap<PathBuf, String>,
    selection: &AnalysisSelection,
) -> Result<SemanticModel> {
    typeck::check_program_types_partial_with_origins(
        program,
        source,
        statement_origins,
        sources,
        selection,
    )?;
    let semantic_model = semantic::analyze_program(program);
    borrowck::check_program_partial_with_origins(
        program,
        &semantic_model,
        statement_origins,
        sources,
        selection,
    )?;
    Ok(semantic_model)
}
