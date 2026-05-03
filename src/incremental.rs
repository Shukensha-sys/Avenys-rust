use crate::avens::{BuildMode, find_project_root};
use crate::error::mss::MssError;
use crate::error::{ErrorKind, MireError, Result};
use crate::parser::Program;
use crate::parser::ast::{
    AssignmentTarget, DataType, EnumVariantDef, Expression, FunctionDef, Identifier, Literal,
    MireValue, QueryBinding, QueryGet, QueryGroup, QueryJoin, QueryOp, Statement, TraitMethodSig,
    Visibility,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs::{self, File};
use std::hash::{Hash, Hasher};
use std::path::{Path, PathBuf};
use std::slice;
use std::time::{SystemTime, UNIX_EPOCH};

#[cfg(unix)]
use std::os::fd::AsRawFd;

const FNV_OFFSET_BASIS: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

pub struct FxHasher {
    state: u64,
}

impl FxHasher {
    pub fn new() -> Self {
        FxHasher {
            state: FNV_OFFSET_BASIS,
        }
    }
}

impl Default for FxHasher {
    fn default() -> Self {
        Self::new()
    }
}

impl Hasher for FxHasher {
    fn finish(&self) -> u64 {
        self.state
    }

    fn write(&mut self, bytes: &[u8]) {
        for &byte in bytes {
            self.state = self.state.wrapping_mul(FNV_PRIME) ^ (byte as u64);
        }
    }

    fn write_u8(&mut self, i: u8) {
        self.state = self.state.wrapping_mul(FNV_PRIME) ^ (i as u64);
    }

    fn write_u16(&mut self, i: u16) {
        self.write(&i.to_le_bytes());
    }

    fn write_u32(&mut self, i: u32) {
        self.write(&i.to_le_bytes());
    }

    fn write_u64(&mut self, i: u64) {
        self.write(&i.to_le_bytes());
    }

    fn write_usize(&mut self, i: usize) {
        self.write(&i.to_le_bytes());
    }
}

const CACHE_DIR_NAME: &str = ".cache";
const CACHE_FILE_NAME: &str = "incremental.bin";
const CACHE_MAGIC: &[u8; 8] = b"MIREINC2";
const CACHE_FORMAT_VERSION: u32 = 5;
const DEFAULT_MAX_UNITS: usize = 256;
const BLOB_COMPACT_THRESHOLD_RATIO: f64 = 0.7;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CacheSettings {
    pub max_units: Option<usize>,
    pub analysis_cache: bool,
    pub compression: bool,
}

#[derive(Debug, Clone, Copy, Default)]
pub struct CacheOverrides {
    pub max_units: Option<usize>,
    pub analysis_cache: Option<bool>,
    pub compression: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CachedImport {
    pub raw_path: String,
    pub resolved_path: PathBuf,
    pub items: Option<Vec<String>>,
}

#[derive(Debug, Clone)]
pub struct CachedParsedFile {
    pub hash: u64,
    pub program: Program,
    pub exports: Vec<String>,
    pub local_imports: Vec<CachedImport>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredParsedFile {
    program: Program,
    exports: Vec<String>,
    local_imports: Vec<CachedImport>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoadedFile {
    pub hash: u64,
    pub direct_dependencies: Vec<PathBuf>,
}

#[derive(Debug, Clone)]
pub struct LoadedProgram {
    pub program: Program,
    pub files: HashMap<PathBuf, LoadedFile>,
    pub statement_origins: Vec<PathBuf>,
    pub sources: HashMap<PathBuf, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildCacheEntry {
    pub fingerprint: u64,
    pub mode: BuildMode,
    pub emit_binary: bool,
    pub persist_ir: bool,
    pub binary_path: PathBuf,
    pub ir_path: Option<PathBuf>,
    pub optimized_ir_path: Option<PathBuf>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredAnalyzedProgram {
    program: Program,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredAnalysisPayload {
    outcome: StoredAnalysisOutcome,
    units: Vec<AnalysisUnitMetadata>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum StoredAnalysisOutcome {
    Success(StoredAnalyzedProgram),
    Error(StoredMireError),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnalysisUnitMetadata {
    pub unit_key: String,
    pub unit_kind: AnalysisUnitKind,
    pub body_hash: u64,
    pub dependencies: Vec<String>,
    pub origin: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AnalysisUnitKind {
    Function,
    Type,
    Class,
    Code,
    Enum,
    Impl,
    Field,
    Other,
}

#[derive(Debug, Clone)]
pub enum CachedAnalysis {
    Success(Program),
    Error(MireError),
}

#[derive(Debug, Clone)]
pub struct CachedAnalysisSnapshot {
    pub program: Program,
    pub units: Vec<AnalysisUnitMetadata>,
}

#[derive(Debug, Clone, Default)]
pub struct AnalysisInvalidationReport {
    pub changed_units: Vec<String>,
    pub invalidated_units: Vec<String>,
    pub added_units: Vec<String>,
    pub removed_units: Vec<String>,
}

#[derive(Debug, Clone, Default)]
pub struct CacheMetrics {
    pub file_hits: u64,
    pub file_misses: u64,
    pub analysis_hits: u64,
    pub analysis_misses: u64,
    pub build_hits: u64,
    pub build_misses: u64,
    pub evictions: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct StoredMireError {
    kind: StoredErrorKind,
    source: Option<String>,
    filename: Option<String>,
    line: usize,
    column: usize,
    explanation: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum StoredErrorKind {
    Lexer {
        line: usize,
        column: usize,
        message: String,
    },
    DeprecatedSyntax {
        line: usize,
        column: usize,
        message: String,
    },
    Parser {
        line: usize,
        column: usize,
        message: String,
    },
    Backend {
        message: String,
    },
    Runtime {
        message: String,
    },
    Type {
        line: usize,
        column: usize,
        message: String,
    },
    Ownership {
        line: usize,
        column: usize,
        kind: StoredMssError,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum StoredMssError {
    MutationWhileShared,
    MultipleMutableRefs,
    MoveWhileBorrowed,
    UseAfterMove,
    DropWhileBorrowed,
    DoubleDrop,
    BorrowOutOfScope,
    InvalidMove,
    UnsafeViolation,
}

#[derive(Debug, Clone, Default)]
struct CacheDb {
    format_version: u32,
    files: HashMap<String, FileCacheEntry>,
    analyses: HashMap<String, AnalysisCacheEntry>,
    builds: HashMap<String, BuildCacheRecord>,
}

#[derive(Debug, Clone)]
struct FileCacheEntry {
    hash: u64,
    blob_offset: u64,
    blob_len: u64,
    last_access_epoch_ms: u64,
}

#[derive(Debug, Clone)]
struct AnalysisCacheEntry {
    fingerprint: u64,
    blob_offset: u64,
    blob_len: u64,
    last_access_epoch_ms: u64,
    created_epoch_ms: u64,
    unit_count: u32,
}

#[derive(Debug, Clone)]
struct BuildCacheRecord {
    entry: BuildCacheEntry,
    last_access_epoch_ms: u64,
}

#[derive(Debug, Clone, Copy)]
struct BlobStoreLayout {
    start: usize,
    len: usize,
}

#[derive(Debug)]
enum BlobStore {
    Owned(Vec<u8>),
    #[cfg(unix)]
    Mapped {
        mapping: MemoryMappedFile,
        layout: BlobStoreLayout,
    },
}

impl Default for BlobStore {
    fn default() -> Self {
        Self::Owned(Vec::new())
    }
}

impl BlobStore {
    fn from_owned(bytes: Vec<u8>) -> Self {
        Self::Owned(bytes)
    }

    #[cfg(unix)]
    fn from_mapped(mapping: MemoryMappedFile, layout: BlobStoreLayout) -> Self {
        Self::Mapped { mapping, layout }
    }

    fn bytes(&self) -> &[u8] {
        match self {
            Self::Owned(bytes) => bytes.as_slice(),
            #[cfg(unix)]
            Self::Mapped { mapping, layout } => {
                let end = layout.start.saturating_add(layout.len);
                &mapping.as_slice()[layout.start..end]
            }
        }
    }

    fn read(&self, offset: u64, len: u64) -> Result<&[u8]> {
        read_blob(self.bytes(), offset, len)
    }

    fn append(&mut self, blob: &[u8]) -> (u64, u64) {
        let store = self.ensure_owned();
        append_blob(store, blob)
    }

    fn ensure_owned(&mut self) -> &mut Vec<u8> {
        if !matches!(self, Self::Owned(_)) {
            let owned = self.bytes().to_vec();
            *self = Self::Owned(owned);
        }

        let Self::Owned(bytes) = self else {
            unreachable!("blob store must be owned after promotion");
        };
        bytes
    }

    #[cfg(test)]
    fn is_memory_mapped(&self) -> bool {
        #[cfg(unix)]
        {
            matches!(self, Self::Mapped { .. })
        }

        #[cfg(not(unix))]
        {
            false
        }
    }
}

#[cfg(unix)]
#[derive(Debug)]
struct MemoryMappedFile {
    ptr: *mut libc::c_void,
    len: usize,
}

#[cfg(unix)]
impl MemoryMappedFile {
    fn map(file: &File) -> Result<Option<Self>> {
        let len = usize::try_from(
            file.metadata()
                .map_err(|err| cache_runtime_err(&format!("Could not stat cache file: {}", err)))?
                .len(),
        )
        .map_err(|_| cache_runtime_err("Incremental cache file too large to map"))?;
        if len == 0 {
            return Ok(None);
        }

        let ptr = unsafe {
            libc::mmap(
                std::ptr::null_mut(),
                len,
                libc::PROT_READ,
                libc::MAP_PRIVATE,
                file.as_raw_fd(),
                0,
            )
        };
        if ptr == libc::MAP_FAILED {
            return Err(cache_runtime_err("Could not memory-map incremental cache"));
        }

        Ok(Some(Self { ptr, len }))
    }

    fn as_slice(&self) -> &[u8] {
        unsafe { slice::from_raw_parts(self.ptr.cast::<u8>(), self.len) }
    }
}

#[cfg(unix)]
impl Drop for MemoryMappedFile {
    fn drop(&mut self) {
        if self.len == 0 {
            return;
        }

        unsafe {
            libc::munmap(self.ptr, self.len);
        }
    }
}

pub struct IncrementalCache {
    cache_path: PathBuf,
    settings: CacheSettings,
    db: CacheDb,
    blob_store: BlobStore,
    metrics: CacheMetrics,
}

impl CacheSettings {
    pub fn defaults() -> Self {
        Self {
            max_units: Some(DEFAULT_MAX_UNITS),
            analysis_cache: true,
            compression: false,
        }
    }

    pub fn resolve_for(source_path: &Path, overrides: CacheOverrides) -> Result<Self> {
        let mut resolved = manifest_cache_settings(source_path)?;
        if let Some(max_units) = overrides.max_units {
            resolved.max_units = (max_units != 0).then_some(max_units);
        }
        if let Some(enabled) = overrides.analysis_cache {
            resolved.analysis_cache = enabled;
        }
        if let Some(enabled) = overrides.compression {
            resolved.compression = enabled;
        }
        Ok(resolved)
    }
}

impl IncrementalCache {
    pub fn load_for(source_path: &Path) -> Result<Self> {
        Self::load_with_settings(
            source_path,
            CacheSettings::resolve_for(source_path, CacheOverrides::default())?,
        )
    }

    pub fn load_with_settings(source_path: &Path, settings: CacheSettings) -> Result<Self> {
        let cache_path = cache_file_path(source_path);
        let mut cache = Self {
            cache_path,
            settings,
            db: CacheDb {
                format_version: CACHE_FORMAT_VERSION,
                ..CacheDb::default()
            },
            blob_store: BlobStore::default(),
            metrics: CacheMetrics::default(),
        };
        let mut found_cache_file = false;
        let mut loaded_cache = false;

        if let Ok(file) = File::open(&cache.cache_path) {
            found_cache_file = true;
            #[cfg(unix)]
            {
                if let Ok(Some(mapping)) = MemoryMappedFile::map(&file) {
                    if let Ok((db, layout)) = decode_cache_db(mapping.as_slice())
                        && db.format_version == CACHE_FORMAT_VERSION
                    {
                        cache.db = db;
                        cache.blob_store = BlobStore::from_mapped(mapping, layout);
                        loaded_cache = true;
                    }
                } else if let Ok(raw) = fs::read(&cache.cache_path)
                    && let Ok((db, layout)) = decode_cache_db(&raw)
                    && db.format_version == CACHE_FORMAT_VERSION
                {
                    cache.db = db;
                    cache.blob_store = BlobStore::from_owned(
                        raw[layout.start..layout.start + layout.len].to_vec(),
                    );
                    loaded_cache = true;
                }
            }

            #[cfg(not(unix))]
            {
                if let Ok(raw) = fs::read(&cache.cache_path) {
                    if let Ok((db, layout)) = decode_cache_db(&raw) {
                        if db.format_version == CACHE_FORMAT_VERSION {
                            cache.db = db;
                            cache.blob_store = BlobStore::from_owned(
                                raw[layout.start..layout.start + layout.len].to_vec(),
                            );
                            loaded_cache = true;
                        }
                    }
                }
            }
        }

        if found_cache_file && !loaded_cache {
            // Best-effort self-heal: keep running with an empty cache and remove corrupt/incompatible file.
            let _ = fs::remove_file(&cache.cache_path);
        }

        cache.prune_lru();
        Ok(cache)
    }

    pub fn save(&mut self) -> Result<()> {
        if let Some(parent) = self.cache_path.parent() {
            fs::create_dir_all(parent).map_err(|err| {
                MireError::new(ErrorKind::Runtime {
                    message: format!(
                        "Could not create incremental cache directory '{}': {}",
                        parent.display(),
                        err
                    ),
                })
            })?;
        }

        self.prune_lru();
        let raw = encode_cache_db(&self.db, self.blob_store.bytes())?;
        fs::write(&self.cache_path, raw).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!(
                    "Could not write incremental cache '{}': {}",
                    self.cache_path.display(),
                    err
                ),
            })
        })
    }

    pub fn metrics(&self) -> &CacheMetrics {
        &self.metrics
    }

    pub fn record_build_hit(&mut self) {
        self.metrics.build_hits += 1;
    }

    pub fn record_build_miss(&mut self) {
        self.metrics.build_misses += 1;
    }

    pub fn cached_file(&mut self, path: &Path, hash: u64) -> Option<CachedParsedFile> {
        let key = normalize_path_key(path);
        let Some(entry) = self.db.files.get(&key) else {
            self.metrics.file_misses += 1;
            return None;
        };
        if entry.hash != hash {
            self.metrics.file_misses += 1;
            return None;
        }

        let blob = self
            .blob_store
            .read(entry.blob_offset, entry.blob_len)
            .ok()?;
        let stored = serde_json::from_slice::<StoredParsedFile>(blob).ok()?;
        if let Some(entry) = self.db.files.get_mut(&key) {
            entry.last_access_epoch_ms = now_epoch_ms();
        }
        self.metrics.file_hits += 1;
        Some(CachedParsedFile {
            hash,
            program: stored.program,
            exports: stored.exports,
            local_imports: stored.local_imports,
        })
    }

    pub fn store_file(&mut self, path: &Path, entry: CachedParsedFile) -> Result<()> {
        let stored = StoredParsedFile {
            program: entry.program,
            exports: entry.exports,
            local_imports: entry.local_imports,
        };
        let blob = serde_json::to_vec(&stored).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Could not serialize cached parsed file: {}", err),
            })
        })?;
        let (blob_offset, blob_len) = self.blob_store.append(&blob);
        self.db.files.insert(
            normalize_path_key(path),
            FileCacheEntry {
                hash: entry.hash,
                blob_offset,
                blob_len,
                last_access_epoch_ms: now_epoch_ms(),
            },
        );
        self.prune_lru();
        Ok(())
    }

    pub fn cached_analysis(
        &mut self,
        source_path: &Path,
        fingerprint: u64,
    ) -> Option<CachedAnalysis> {
        if !self.settings.analysis_cache {
            return None;
        }

        let key = analysis_cache_key(source_path, fingerprint);
        let Some(entry) = self.db.analyses.get(&key) else {
            self.metrics.analysis_misses += 1;
            return None;
        };
        if entry.fingerprint != fingerprint {
            self.metrics.analysis_misses += 1;
            return None;
        }

        let blob = self
            .blob_store
            .read(entry.blob_offset, entry.blob_len)
            .ok()?;
        let stored = serde_json::from_slice::<StoredAnalysisPayload>(blob).ok()?;
        if let Some(entry) = self.db.analyses.get_mut(&key) {
            entry.last_access_epoch_ms = now_epoch_ms();
        }
        self.metrics.analysis_hits += 1;
        match stored.outcome {
            StoredAnalysisOutcome::Success(stored) => Some(CachedAnalysis::Success(stored.program)),
            StoredAnalysisOutcome::Error(error) => Some(CachedAnalysis::Error(error.into())),
        }
    }

    pub fn store_analysis(
        &mut self,
        source_path: &Path,
        fingerprint: u64,
        program: &Program,
    ) -> Result<()> {
        if !self.settings.analysis_cache {
            return Ok(());
        }

        let units = analysis_units_for_program(program);
        let stored = StoredAnalysisPayload {
            outcome: StoredAnalysisOutcome::Success(StoredAnalyzedProgram {
                program: program.clone(),
            }),
            units: units.clone(),
        };
        let blob = serde_json::to_vec(&stored).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Could not serialize analysis cache entry: {}", err),
            })
        })?;
        let (blob_offset, blob_len) = self.blob_store.append(&blob);
        let now = now_epoch_ms();
        self.db.analyses.insert(
            analysis_cache_key(source_path, fingerprint),
            AnalysisCacheEntry {
                fingerprint,
                blob_offset,
                blob_len,
                last_access_epoch_ms: now,
                created_epoch_ms: now,
                unit_count: units.len() as u32,
            },
        );
        self.prune_lru();
        Ok(())
    }

    pub fn store_analysis_error(
        &mut self,
        source_path: &Path,
        fingerprint: u64,
        program: &Program,
        error: &MireError,
    ) -> Result<()> {
        if !self.settings.analysis_cache {
            return Ok(());
        }

        let units = analysis_units_for_program(program);
        let stored = StoredAnalysisPayload {
            outcome: StoredAnalysisOutcome::Error(error.into()),
            units: units.clone(),
        };
        let blob = serde_json::to_vec(&stored).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Could not serialize cached analysis error: {}", err),
            })
        })?;
        let (blob_offset, blob_len) = self.blob_store.append(&blob);
        let now = now_epoch_ms();
        self.db.analyses.insert(
            analysis_cache_key(source_path, fingerprint),
            AnalysisCacheEntry {
                fingerprint,
                blob_offset,
                blob_len,
                last_access_epoch_ms: now,
                created_epoch_ms: now,
                unit_count: units.len() as u32,
            },
        );
        self.prune_lru();
        Ok(())
    }

    pub fn analysis_invalidation_report(
        &self,
        source_path: &Path,
        program: &Program,
    ) -> Option<AnalysisInvalidationReport> {
        let current_units = analysis_units_for_program(program);
        let previous_units = self.latest_analysis_units(source_path)?;
        Some(compute_invalidation_report(&previous_units, &current_units))
    }

    pub fn latest_successful_analysis(
        &mut self,
        source_path: &Path,
    ) -> Option<CachedAnalysisSnapshot> {
        let prefix = format!("{}::analysis::", normalize_path_key(source_path));
        let mut latest_key: Option<String> = None;
        let mut latest_created = 0_u64;

        for (key, entry) in &self.db.analyses {
            if key.starts_with(&prefix) && entry.created_epoch_ms >= latest_created {
                latest_created = entry.created_epoch_ms;
                latest_key = Some(key.clone());
            }
        }

        let key = latest_key?;
        let entry = self.db.analyses.get(&key)?;
        let blob = self
            .blob_store
            .read(entry.blob_offset, entry.blob_len)
            .ok()?;
        let stored = serde_json::from_slice::<StoredAnalysisPayload>(blob).ok()?;
        let StoredAnalysisOutcome::Success(stored_program) = stored.outcome else {
            return None;
        };
        if let Some(entry) = self.db.analyses.get_mut(&key) {
            entry.last_access_epoch_ms = now_epoch_ms();
        }
        Some(CachedAnalysisSnapshot {
            program: stored_program.program,
            units: stored.units,
        })
    }

    pub fn build_entry(
        &mut self,
        source_path: &Path,
        mode: BuildMode,
        emit_binary: bool,
        persist_ir: bool,
    ) -> Option<&BuildCacheEntry> {
        let key = build_cache_key(source_path, mode, emit_binary, persist_ir);
        let record = self.db.builds.get_mut(&key)?;
        record.last_access_epoch_ms = now_epoch_ms();
        Some(&record.entry)
    }

    pub fn store_build(&mut self, source_path: &Path, entry: BuildCacheEntry) {
        self.db.builds.insert(
            build_cache_key(source_path, entry.mode, entry.emit_binary, entry.persist_ir),
            BuildCacheRecord {
                entry,
                last_access_epoch_ms: now_epoch_ms(),
            },
        );
    }

    fn prune_lru(&mut self) {
        let Some(max_units) = self.settings.max_units else {
            self.maybe_compact_blob_store();
            return;
        };

        let current_units = self.db.files.len() + self.db.analyses.len() + self.db.builds.len();
        if current_units <= max_units {
            self.maybe_compact_blob_store();
            return;
        }

        let mut victims = Vec::with_capacity(current_units);
        for key in self.db.files.keys() {
            let last_access = self
                .db
                .files
                .get(key)
                .map(|entry| entry.last_access_epoch_ms)
                .unwrap_or(0);
            victims.push((last_access, CacheVictim::File(key.clone())));
        }
        for key in self.db.analyses.keys() {
            let last_access = self
                .db
                .analyses
                .get(key)
                .map(|entry| entry.last_access_epoch_ms)
                .unwrap_or(0);
            victims.push((last_access, CacheVictim::Analysis(key.clone())));
        }
        for key in self.db.builds.keys() {
            let last_access = self
                .db
                .builds
                .get(key)
                .map(|entry| entry.last_access_epoch_ms)
                .unwrap_or(0);
            victims.push((last_access, CacheVictim::Build(key.clone())));
        }
        victims.sort_by_key(|(last_access, _)| *last_access);

        let to_remove = current_units.saturating_sub(max_units);
        for (_, victim) in victims.into_iter().take(to_remove) {
            match victim {
                CacheVictim::File(key) => {
                    self.db.files.remove(&key);
                    self.metrics.evictions += 1;
                }
                CacheVictim::Analysis(key) => {
                    self.db.analyses.remove(&key);
                    self.metrics.evictions += 1;
                }
                CacheVictim::Build(key) => {
                    self.db.builds.remove(&key);
                    self.metrics.evictions += 1;
                }
            }
        }

        self.maybe_compact_blob_store();
    }

    fn maybe_compact_blob_store(&mut self) {
        let total_len = self.blob_store.bytes().len();
        if total_len < 512 {
            return;
        }

        let mut live_ranges = Vec::with_capacity(self.db.files.len() + self.db.analyses.len());
        for entry in self.db.files.values() {
            live_ranges.push((entry.blob_offset, entry.blob_len));
        }
        for entry in self.db.analyses.values() {
            live_ranges.push((entry.blob_offset, entry.blob_len));
        }

        if live_ranges.is_empty() {
            if total_len > 0 {
                self.blob_store = BlobStore::from_owned(Vec::new());
            }
            return;
        }

        live_ranges.sort_unstable_by_key(|(offset, _)| *offset);
        let mut unique_live_ranges = Vec::with_capacity(live_ranges.len());
        for (offset, len) in live_ranges {
            let start = offset as usize;
            let end = start.saturating_add(len as usize).min(total_len);
            if start >= end {
                continue;
            }
            if let Some((_, last_end)) = unique_live_ranges.last_mut() {
                if start <= *last_end {
                    *last_end = (*last_end).max(end);
                    continue;
                }
            }
            unique_live_ranges.push((start, end));
        }

        let live_bytes = unique_live_ranges.iter().fold(0usize, |acc, (start, end)| {
            acc.saturating_add(end.saturating_sub(*start))
        });
        if live_bytes == 0 {
            if total_len > 0 {
                self.blob_store = BlobStore::from_owned(Vec::new());
            }
            return;
        }

        let ratio = (live_bytes as f64) / (total_len as f64);
        if ratio >= BLOB_COMPACT_THRESHOLD_RATIO {
            return;
        }

        let old_blob = self.blob_store.bytes();
        let mut compacted = Vec::with_capacity(live_bytes);
        let mut relocated_ranges = Vec::with_capacity(unique_live_ranges.len());

        for (old_start, old_end) in unique_live_ranges {
            let new_offset = compacted.len() as u64;
            compacted.extend_from_slice(&old_blob[old_start..old_end]);
            relocated_ranges.push((old_start as u64, old_end as u64, new_offset));
        }

        for entry in self.db.files.values_mut() {
            if let Some((old_start, _old_end, new_start)) = relocated_ranges
                .iter()
                .find(|(old_start, old_end, _)| {
                    entry.blob_offset >= *old_start
                        && entry.blob_offset.saturating_add(entry.blob_len) <= *old_end
                })
            {
                entry.blob_offset = new_start.saturating_add(entry.blob_offset - *old_start);
            }
        }
        for entry in self.db.analyses.values_mut() {
            if let Some((old_start, _old_end, new_start)) = relocated_ranges
                .iter()
                .find(|(old_start, old_end, _)| {
                    entry.blob_offset >= *old_start
                        && entry.blob_offset.saturating_add(entry.blob_len) <= *old_end
                })
            {
                entry.blob_offset = new_start.saturating_add(entry.blob_offset - *old_start);
            }
        }

        self.blob_store = BlobStore::from_owned(compacted);
    }

    fn latest_analysis_units(&self, source_path: &Path) -> Option<Vec<AnalysisUnitMetadata>> {
        let prefix = format!("{}::analysis::", normalize_path_key(source_path));
        let mut latest_key: Option<&str> = None;
        let mut latest_created = 0_u64;

        for (key, entry) in &self.db.analyses {
            if key.starts_with(&prefix) && entry.created_epoch_ms >= latest_created {
                latest_created = entry.created_epoch_ms;
                latest_key = Some(key.as_str());
            }
        }

        let key = latest_key?;
        let entry = self.db.analyses.get(key)?;
        let blob = self
            .blob_store
            .read(entry.blob_offset, entry.blob_len)
            .ok()?;
        let stored = serde_json::from_slice::<StoredAnalysisPayload>(blob).ok()?;
        Some(stored.units)
    }
}

enum CacheVictim {
    File(String),
    Analysis(String),
    Build(String),
}

pub fn cache_file_path(source_path: &Path) -> PathBuf {
    let base = if let Some(project_root) =
        find_project_root(source_path.parent().unwrap_or_else(|| Path::new(".")))
    {
        project_root.join("bin")
    } else {
        source_path
            .parent()
            .unwrap_or_else(|| Path::new("."))
            .to_path_buf()
    };

    base.join(CACHE_DIR_NAME).join(CACHE_FILE_NAME)
}

pub fn source_hash(source: &str) -> u64 {
    let mut hasher = FxHasher::new();
    source.hash(&mut hasher);
    hasher.finish()
}

pub fn build_fingerprint(
    source_path: &Path,
    files: &HashMap<PathBuf, LoadedFile>,
    mode: BuildMode,
    emit_binary: bool,
    runtime_support: &str,
) -> u64 {
    let mut hasher = FxHasher::new();
    normalize_path_key(source_path).hash(&mut hasher);
    mode.hash(&mut hasher);
    emit_binary.hash(&mut hasher);
    env!("CARGO_PKG_VERSION").hash(&mut hasher);
    runtime_support.hash(&mut hasher);

    let mut file_entries: Vec<_> = files.iter().collect();
    file_entries.sort_by_key(|(left, _)| *left);
    for (path, info) in file_entries {
        normalize_path_key(path).hash(&mut hasher);
        info.hash.hash(&mut hasher);

        let mut deps = info.direct_dependencies.clone();
        deps.sort();
        for dependency in deps {
            normalize_path_key(&dependency).hash(&mut hasher);
        }
    }

    hasher.finish()
}

fn build_cache_key(
    source_path: &Path,
    mode: BuildMode,
    emit_binary: bool,
    persist_ir: bool,
) -> String {
    format!(
        "{}::{mode:?}::{emit_binary}::{persist_ir}",
        normalize_path_key(source_path)
    )
}

fn analysis_cache_key(source_path: &Path, fingerprint: u64) -> String {
    format!(
        "{}::analysis::{fingerprint}",
        normalize_path_key(source_path)
    )
}

fn normalize_path_key(path: &Path) -> String {
    path.to_string_lossy().to_string()
}

pub fn statement_export_name(statement: &Statement) -> Option<&str> {
    match statement {
        Statement::Let { name, .. }
        | Statement::Function { name, .. }
        | Statement::Type { name, .. }
        | Statement::Class { name, .. }
        | Statement::Trait { name, .. }
        | Statement::Skill { name, .. }
        | Statement::Module { name, .. }
        | Statement::Enum { name, .. }
        | Statement::ExternLib { name, .. }
        | Statement::ExternFunction { name, .. } => Some(name.as_str()),
        _ => None,
    }
}

fn manifest_cache_settings(source_path: &Path) -> Result<CacheSettings> {
    let Some(project_root) =
        find_project_root(source_path.parent().unwrap_or_else(|| Path::new(".")))
    else {
        return Ok(CacheSettings::defaults());
    };

    let manifest_path = project_root.join("project.toml");
    let raw = match fs::read_to_string(&manifest_path) {
        Ok(raw) => raw,
        Err(_) => return Ok(CacheSettings::defaults()),
    };

    #[derive(Deserialize)]
    struct ManifestFile {
        cache: Option<ManifestCache>,
    }

    #[derive(Deserialize)]
    struct ManifestCache {
        max_units: Option<usize>,
        analysis_cache: Option<bool>,
        compression: Option<bool>,
    }

    let manifest = toml::from_str::<ManifestFile>(&raw).map_err(|err| {
        MireError::new(ErrorKind::Runtime {
            message: format!("Invalid project.toml cache configuration: {}", err),
        })
    })?;
    let defaults = CacheSettings::defaults();
    let cache = manifest.cache;
    let max_units = cache
        .as_ref()
        .and_then(|cache| cache.max_units)
        .unwrap_or(DEFAULT_MAX_UNITS);

    Ok(CacheSettings {
        max_units: (max_units != 0).then_some(max_units),
        analysis_cache: cache
            .as_ref()
            .and_then(|cache| cache.analysis_cache)
            .unwrap_or(defaults.analysis_cache),
        compression: cache
            .as_ref()
            .and_then(|cache| cache.compression)
            .unwrap_or(defaults.compression),
    })
}

fn encode_cache_db(db: &CacheDb, blob_store: &[u8]) -> Result<Vec<u8>> {
    let mut out = Vec::with_capacity(blob_store.len().saturating_add(4096));
    out.extend_from_slice(CACHE_MAGIC);
    write_u32(&mut out, CACHE_FORMAT_VERSION);
    write_u64(
        &mut out,
        u64::try_from(db.files.len()).map_err(|_| cache_runtime_err("Too many cached files"))?,
    );
    for (key, entry) in &db.files {
        write_string(&mut out, key)?;
        write_u64(&mut out, entry.hash);
        write_u64(&mut out, entry.last_access_epoch_ms);
        write_u64(&mut out, entry.blob_offset);
        write_u64(&mut out, entry.blob_len);
    }

    write_u64(
        &mut out,
        u64::try_from(db.analyses.len())
            .map_err(|_| cache_runtime_err("Too many cached analysis entries"))?,
    );
    for (key, entry) in &db.analyses {
        write_string(&mut out, key)?;
        write_u64(&mut out, entry.fingerprint);
        write_u64(&mut out, entry.last_access_epoch_ms);
        write_u64(&mut out, entry.created_epoch_ms);
        write_u64(&mut out, entry.blob_offset);
        write_u64(&mut out, entry.blob_len);
        write_u32(&mut out, entry.unit_count);
    }

    write_u64(
        &mut out,
        u64::try_from(db.builds.len()).map_err(|_| cache_runtime_err("Too many cached builds"))?,
    );
    for (key, record) in &db.builds {
        write_string(&mut out, key)?;
        write_u64(&mut out, record.last_access_epoch_ms);
        write_build_entry(&mut out, &record.entry)?;
    }

    write_u64(
        &mut out,
        u64::try_from(blob_store.len()).map_err(|_| cache_runtime_err("Blob store too large"))?,
    );
    out.extend_from_slice(blob_store);
    Ok(out)
}

fn decode_cache_db(raw: &[u8]) -> Result<(CacheDb, BlobStoreLayout)> {
    let mut cursor = Cursor::new(raw);
    let magic = cursor.read_exact_bytes(CACHE_MAGIC.len())?;
    if magic != CACHE_MAGIC {
        return Err(cache_runtime_err("Invalid incremental cache header"));
    }

    let format_version = cursor.read_u32()?;
    let file_count = usize::try_from(cursor.read_u64()?)
        .map_err(|_| cache_runtime_err("Invalid cached file count"))?;
    let mut files = HashMap::with_capacity(file_count);
    for _ in 0..file_count {
        let key = cursor.read_string()?;
        let hash = cursor.read_u64()?;
        let last_access_epoch_ms = cursor.read_u64()?;
        let blob_offset = cursor.read_u64()?;
        let blob_len = cursor.read_u64()?;
        files.insert(
            key,
            FileCacheEntry {
                hash,
                blob_offset,
                blob_len,
                last_access_epoch_ms,
            },
        );
    }

    let analysis_count = usize::try_from(cursor.read_u64()?)
        .map_err(|_| cache_runtime_err("Invalid cached analysis count"))?;
    let mut analyses = HashMap::with_capacity(analysis_count);
    for _ in 0..analysis_count {
        let key = cursor.read_string()?;
        let fingerprint = cursor.read_u64()?;
        let last_access_epoch_ms = cursor.read_u64()?;
        let created_epoch_ms = cursor.read_u64()?;
        let blob_offset = cursor.read_u64()?;
        let blob_len = cursor.read_u64()?;
        let unit_count = cursor.read_u32()?;
        let entry = AnalysisCacheEntry {
            fingerprint,
            blob_offset,
            blob_len,
            last_access_epoch_ms,
            created_epoch_ms,
            unit_count,
        };
        let entry = if entry.created_epoch_ms == 0 {
            AnalysisCacheEntry {
                created_epoch_ms: entry.last_access_epoch_ms,
                ..entry
            }
        } else {
            entry
        };
        analyses.insert(key, entry);
    }

    let build_count = usize::try_from(cursor.read_u64()?)
        .map_err(|_| cache_runtime_err("Invalid cached build count"))?;
    let mut builds = HashMap::with_capacity(build_count);
    for _ in 0..build_count {
        let key = cursor.read_string()?;
        let last_access_epoch_ms = cursor.read_u64()?;
        let entry = cursor.read_build_entry()?;
        builds.insert(
            key,
            BuildCacheRecord {
                entry,
                last_access_epoch_ms,
            },
        );
    }

    let blob_len = usize::try_from(cursor.read_u64()?)
        .map_err(|_| cache_runtime_err("Invalid blob store length"))?;
    let blob_start = cursor.position();
    cursor.read_exact_bytes(blob_len)?;

    Ok((
        CacheDb {
            format_version,
            files,
            analyses,
            builds,
        },
        BlobStoreLayout {
            start: blob_start,
            len: blob_len,
        },
    ))
}

fn append_blob(blob_store: &mut Vec<u8>, blob: &[u8]) -> (u64, u64) {
    let offset = blob_store.len() as u64;
    blob_store.extend_from_slice(blob);
    (offset, blob.len() as u64)
}

fn read_blob(blob_store: &[u8], offset: u64, len: u64) -> Result<&[u8]> {
    let start = usize::try_from(offset).map_err(|_| cache_runtime_err("Invalid cache offset"))?;
    let len = usize::try_from(len).map_err(|_| cache_runtime_err("Invalid cache length"))?;
    let end = start
        .checked_add(len)
        .ok_or_else(|| cache_runtime_err("Invalid cache blob range"))?;
    blob_store
        .get(start..end)
        .ok_or_else(|| cache_runtime_err("Cache blob out of bounds"))
}

fn write_build_entry(out: &mut Vec<u8>, entry: &BuildCacheEntry) -> Result<()> {
    write_u64(out, entry.fingerprint);
    write_u8(
        out,
        match entry.mode {
            BuildMode::Debug => 0,
            BuildMode::Release => 1,
        },
    );
    write_bool(out, entry.emit_binary);
    write_bool(out, entry.persist_ir);
    write_path(out, &entry.binary_path)?;
    write_optional_path(out, entry.ir_path.as_ref())?;
    write_optional_path(out, entry.optimized_ir_path.as_ref())?;
    Ok(())
}

fn write_optional_path(out: &mut Vec<u8>, path: Option<&PathBuf>) -> Result<()> {
    match path {
        Some(path) => {
            write_bool(out, true);
            write_path(out, path)?;
        }
        None => write_bool(out, false),
    }
    Ok(())
}

fn write_path(out: &mut Vec<u8>, path: &Path) -> Result<()> {
    write_string(out, &path.to_string_lossy())
}

fn write_string(out: &mut Vec<u8>, value: &str) -> Result<()> {
    write_u64(
        out,
        u64::try_from(value.len()).map_err(|_| cache_runtime_err("String too large"))?,
    );
    out.extend_from_slice(value.as_bytes());
    Ok(())
}

fn write_u64(out: &mut Vec<u8>, value: u64) {
    out.extend_from_slice(&value.to_le_bytes());
}

fn write_u32(out: &mut Vec<u8>, value: u32) {
    out.extend_from_slice(&value.to_le_bytes());
}

fn write_u8(out: &mut Vec<u8>, value: u8) {
    out.push(value);
}

fn write_bool(out: &mut Vec<u8>, value: bool) {
    write_u8(out, u8::from(value));
}

fn now_epoch_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

fn cache_runtime_err(message: &str) -> MireError {
    MireError::new(ErrorKind::Runtime {
        message: message.to_string(),
    })
}

struct Cursor<'a> {
    raw: &'a [u8],
    pos: usize,
}

impl<'a> Cursor<'a> {
    fn new(raw: &'a [u8]) -> Self {
        Self { raw, pos: 0 }
    }

    fn position(&self) -> usize {
        self.pos
    }

    fn read_exact_bytes(&mut self, len: usize) -> Result<&'a [u8]> {
        let end = self
            .pos
            .checked_add(len)
            .ok_or_else(|| cache_runtime_err("Cache cursor overflow"))?;
        let slice = self
            .raw
            .get(self.pos..end)
            .ok_or_else(|| cache_runtime_err("Unexpected end of incremental cache"))?;
        self.pos = end;
        Ok(slice)
    }

    fn read_u64(&mut self) -> Result<u64> {
        let bytes = self.read_exact_bytes(8)?;
        let mut array = [0_u8; 8];
        array.copy_from_slice(bytes);
        Ok(u64::from_le_bytes(array))
    }

    fn read_u32(&mut self) -> Result<u32> {
        let bytes = self.read_exact_bytes(4)?;
        let mut array = [0_u8; 4];
        array.copy_from_slice(bytes);
        Ok(u32::from_le_bytes(array))
    }

    fn read_u8(&mut self) -> Result<u8> {
        Ok(*self
            .read_exact_bytes(1)?
            .first()
            .ok_or_else(|| cache_runtime_err("Missing cache byte"))?)
    }

    fn read_bool(&mut self) -> Result<bool> {
        Ok(self.read_u8()? != 0)
    }

    fn read_string(&mut self) -> Result<String> {
        let len = usize::try_from(self.read_u64()?)
            .map_err(|_| cache_runtime_err("Invalid cache string length"))?;
        let bytes = self.read_exact_bytes(len)?;
        String::from_utf8(bytes.to_vec()).map_err(|err| {
            MireError::new(ErrorKind::Runtime {
                message: format!("Invalid UTF-8 in incremental cache: {}", err),
            })
        })
    }

    fn read_path(&mut self) -> Result<PathBuf> {
        Ok(PathBuf::from(self.read_string()?))
    }

    fn read_optional_path(&mut self) -> Result<Option<PathBuf>> {
        if self.read_bool()? {
            Ok(Some(self.read_path()?))
        } else {
            Ok(None)
        }
    }

    fn read_build_entry(&mut self) -> Result<BuildCacheEntry> {
        let fingerprint = self.read_u64()?;
        let mode = match self.read_u8()? {
            0 => BuildMode::Debug,
            1 => BuildMode::Release,
            _ => return Err(cache_runtime_err("Invalid build mode in cache")),
        };
        let emit_binary = self.read_bool()?;
        let persist_ir = self.read_bool()?;
        let binary_path = self.read_path()?;
        let ir_path = self.read_optional_path()?;
        let optimized_ir_path = self.read_optional_path()?;
        Ok(BuildCacheEntry {
            fingerprint,
            mode,
            emit_binary,
            persist_ir,
            binary_path,
            ir_path,
            optimized_ir_path,
        })
    }
}

impl From<&MireError> for StoredMireError {
    fn from(value: &MireError) -> Self {
        Self {
            kind: (&value.kind).into(),
            source: value.source().cloned(),
            filename: value.filename().cloned(),
            line: value.line,
            column: value.column,
            explanation: value.explanation().cloned(),
        }
    }
}

impl From<StoredMireError> for MireError {
    fn from(value: StoredMireError) -> Self {
        let mut error = MireError::new(value.kind.into());
        error.set_source(value.source);
        error.set_filename(value.filename);
        error.line = value.line;
        error.column = value.column;
        error.set_explanation(value.explanation);
        error
    }
}

impl From<&ErrorKind> for StoredErrorKind {
    fn from(value: &ErrorKind) -> Self {
        match value {
            ErrorKind::Lexer {
                line,
                column,
                message,
            } => Self::Lexer {
                line: *line,
                column: *column,
                message: message.clone(),
            },
            ErrorKind::DeprecatedSyntax {
                line,
                column,
                message,
            } => Self::DeprecatedSyntax {
                line: *line,
                column: *column,
                message: message.clone(),
            },
            ErrorKind::Parser {
                line,
                column,
                message,
            } => Self::Parser {
                line: *line,
                column: *column,
                message: message.clone(),
            },
            ErrorKind::Backend { message } => Self::Backend {
                message: message.clone(),
            },
            ErrorKind::Runtime { message } => Self::Runtime {
                message: message.clone(),
            },
            ErrorKind::Type {
                line,
                column,
                message,
            } => Self::Type {
                line: *line,
                column: *column,
                message: message.clone(),
            },
            ErrorKind::Ownership { line, column, kind } => Self::Ownership {
                line: *line,
                column: *column,
                kind: kind.into(),
            },
        }
    }
}

impl From<StoredErrorKind> for ErrorKind {
    fn from(value: StoredErrorKind) -> Self {
        match value {
            StoredErrorKind::Lexer {
                line,
                column,
                message,
            } => Self::Lexer {
                line,
                column,
                message,
            },
            StoredErrorKind::DeprecatedSyntax {
                line,
                column,
                message,
            } => Self::DeprecatedSyntax {
                line,
                column,
                message,
            },
            StoredErrorKind::Parser {
                line,
                column,
                message,
            } => Self::Parser {
                line,
                column,
                message,
            },
            StoredErrorKind::Backend { message } => Self::Backend { message },
            StoredErrorKind::Runtime { message } => Self::Runtime { message },
            StoredErrorKind::Type {
                line,
                column,
                message,
            } => Self::Type {
                line,
                column,
                message,
            },
            StoredErrorKind::Ownership { line, column, kind } => Self::Ownership {
                line,
                column,
                kind: kind.into(),
            },
        }
    }
}

impl From<&MssError> for StoredMssError {
    fn from(value: &MssError) -> Self {
        match value {
            MssError::MutationWhileShared => Self::MutationWhileShared,
            MssError::MultipleMutableRefs => Self::MultipleMutableRefs,
            MssError::MoveWhileBorrowed => Self::MoveWhileBorrowed,
            MssError::UseAfterMove => Self::UseAfterMove,
            MssError::DropWhileBorrowed => Self::DropWhileBorrowed,
            MssError::DoubleDrop => Self::DoubleDrop,
            MssError::BorrowOutOfScope => Self::BorrowOutOfScope,
            MssError::InvalidMove => Self::InvalidMove,
            MssError::UnsafeViolation => Self::UnsafeViolation,
        }
    }
}

impl From<StoredMssError> for MssError {
    fn from(value: StoredMssError) -> Self {
        match value {
            StoredMssError::MutationWhileShared => Self::MutationWhileShared,
            StoredMssError::MultipleMutableRefs => Self::MultipleMutableRefs,
            StoredMssError::MoveWhileBorrowed => Self::MoveWhileBorrowed,
            StoredMssError::UseAfterMove => Self::UseAfterMove,
            StoredMssError::DropWhileBorrowed => Self::DropWhileBorrowed,
            StoredMssError::DoubleDrop => Self::DoubleDrop,
            StoredMssError::BorrowOutOfScope => Self::BorrowOutOfScope,
            StoredMssError::InvalidMove => Self::InvalidMove,
            StoredMssError::UnsafeViolation => Self::UnsafeViolation,
        }
    }
}

pub fn analysis_units_for_program(program: &Program) -> Vec<AnalysisUnitMetadata> {
    let mut units = Vec::new();
    for statement in &program.statements {
        collect_analysis_units(statement, &mut units);
    }
    units
}

pub fn compute_invalidation_report(
    previous_units: &[AnalysisUnitMetadata],
    current_units: &[AnalysisUnitMetadata],
) -> AnalysisInvalidationReport {
    let previous_by_key: HashMap<_, _> = previous_units
        .iter()
        .map(|unit| (unit.unit_key.clone(), unit))
        .collect();
    let current_by_key: HashMap<_, _> = current_units
        .iter()
        .map(|unit| (unit.unit_key.clone(), unit))
        .collect();

    let mut changed_units = Vec::new();
    let mut added_units = Vec::new();
    let mut removed_units = Vec::new();

    for (key, current) in &current_by_key {
        match previous_by_key.get(key) {
            Some(previous) => {
                if previous.body_hash != current.body_hash
                    || previous.dependencies != current.dependencies
                    || previous.unit_kind != current.unit_kind
                {
                    changed_units.push(key.clone());
                }
            }
            None => added_units.push(key.clone()),
        }
    }

    for key in previous_by_key.keys() {
        if !current_by_key.contains_key(key) {
            removed_units.push(key.clone());
        }
    }

    let mut reverse_dependencies: HashMap<String, Vec<String>> = HashMap::new();
    for current in current_units {
        for dep in &current.dependencies {
            reverse_dependencies
                .entry(dep.clone())
                .or_default()
                .push(current.unit_key.clone());
        }
    }

    let mut invalidated: HashMap<String, ()> = HashMap::new();
    let mut queue = changed_units.clone();
    queue.extend(added_units.clone());
    queue.extend(removed_units.clone());
    let mut queued: HashMap<String, ()> = queue.iter().cloned().map(|k| (k, ())).collect();

    while let Some(unit) = queue.pop() {
        queued.remove(&unit);
        if invalidated.insert(unit.clone(), ()).is_some() {
            continue;
        }

        let mut keys = vec![unit.clone()];
        if let Some((_, suffix)) = unit.rsplit_once('.') {
            keys.push(suffix.to_string());
        }
        if let Some((_, suffix)) = unit.rsplit_once('#') {
            keys.push(suffix.to_string());
        }

        for key in keys {
            if let Some(dependents) = reverse_dependencies.get(&key) {
                for dependent in dependents {
                    if !invalidated.contains_key(dependent) && !queued.contains_key(dependent) {
                        queue.push(dependent.clone());
                        queued.insert(dependent.clone(), ());
                    }
                }
            }
        }
    }

    let mut invalidated_units: Vec<_> = invalidated.into_keys().collect();
    changed_units.sort();
    added_units.sort();
    removed_units.sort();
    invalidated_units.sort();

    AnalysisInvalidationReport {
        changed_units,
        invalidated_units,
        added_units,
        removed_units,
    }
}

fn collect_analysis_units(statement: &Statement, units: &mut Vec<AnalysisUnitMetadata>) {
    let unit = analysis_unit_for_statement(statement);
    let parent_key = unit.unit_key.clone();
    let parent_kind = unit.unit_kind;
    units.push(unit);

    if let Some(children) = direct_analysis_children(statement) {
        for (child_index, child) in children.iter().enumerate() {
            units.push(analysis_child_unit_for_statement(
                &parent_key,
                parent_kind,
                child,
                child_index,
            ));
        }
    }
}

fn analysis_unit_for_statement(statement: &Statement) -> AnalysisUnitMetadata {
    let mut dependencies = Vec::new();
    collect_statement_dependencies(statement, &mut dependencies);
    dependencies.sort();
    dependencies.dedup();

    let (unit_key, unit_kind) = match statement {
        Statement::Function { name, .. } => (name.clone(), AnalysisUnitKind::Function),
        Statement::Type { name, .. } => (name.clone(), AnalysisUnitKind::Type),
        Statement::Class { name, .. } => (name.clone(), AnalysisUnitKind::Class),
        Statement::Code {
            trait_name,
            type_name,
            ..
        } => (
            format!("code::{trait_name}::{type_name}"),
            AnalysisUnitKind::Code,
        ),
        Statement::Enum { name, .. } => (name.clone(), AnalysisUnitKind::Enum),
        Statement::Impl { type_name, .. } => (format!("impl::{type_name}"), AnalysisUnitKind::Impl),
        other => (
            statement_export_name(other)
                .map(ToString::to_string)
                .unwrap_or_else(|| format!("{other:?}")),
            AnalysisUnitKind::Other,
        ),
    };

    AnalysisUnitMetadata {
        unit_key,
        unit_kind,
        body_hash: stable_statement_hash(statement),
        dependencies,
        origin: None,
    }
}

pub fn analysis_unit_key(statement: &Statement) -> String {
    analysis_unit_for_statement(statement).unit_key
}

pub fn analysis_child_unit_key(parent_key: &str, child: &Statement, child_index: usize) -> String {
    match child {
        Statement::Function { name, .. } => {
            if let Some(type_name) = parent_key.strip_prefix("impl::") {
                format!("{type_name}.{name}")
            } else if let Some(rest) = parent_key.strip_prefix("code::") {
                let type_name = rest
                    .rsplit_once("::")
                    .map(|(_, type_name)| type_name)
                    .unwrap_or(rest);
                format!("{type_name}.{name}")
            } else {
                format!("{parent_key}.{name}")
            }
        }
        Statement::Let { name, .. } => format!("{parent_key}#{name}"),
        Statement::Type { name, .. }
        | Statement::Class { name, .. }
        | Statement::Enum { name, .. } => format!("{parent_key}::{name}"),
        Statement::Code {
            trait_name,
            type_name,
            ..
        } => format!("{parent_key}::code::{trait_name}::{type_name}"),
        Statement::Impl {
            trait_name,
            type_name,
            ..
        } => format!(
            "{parent_key}::impl::{}::{type_name}",
            trait_name.as_deref().unwrap_or("_")
        ),
        _ => format!("{parent_key}::item::{child_index}"),
    }
}

fn analysis_child_unit_for_statement(
    parent_key: &str,
    parent_kind: AnalysisUnitKind,
    child: &Statement,
    child_index: usize,
) -> AnalysisUnitMetadata {
    let mut dependencies = Vec::new();
    collect_statement_dependencies(child, &mut dependencies);
    dependencies.push(parent_key.to_string());
    dependencies.sort();
    dependencies.dedup();

    let unit_kind = match child {
        Statement::Function { .. } => AnalysisUnitKind::Function,
        Statement::Let { .. }
            if matches!(
                parent_kind,
                AnalysisUnitKind::Type | AnalysisUnitKind::Class
            ) =>
        {
            AnalysisUnitKind::Field
        }
        Statement::Type { .. } => AnalysisUnitKind::Type,
        Statement::Class { .. } => AnalysisUnitKind::Class,
        Statement::Code { .. } => AnalysisUnitKind::Code,
        Statement::Enum { .. } => AnalysisUnitKind::Enum,
        Statement::Impl { .. } => AnalysisUnitKind::Impl,
        _ => AnalysisUnitKind::Other,
    };

    AnalysisUnitMetadata {
        unit_key: analysis_child_unit_key(parent_key, child, child_index),
        unit_kind,
        body_hash: stable_statement_hash(child),
        dependencies,
        origin: None,
    }
}

fn direct_analysis_children(statement: &Statement) -> Option<&[Statement]> {
    match statement {
        Statement::Type { fields, .. } => Some(fields.as_slice()),
        Statement::Class { methods, .. }
        | Statement::Code { methods, .. }
        | Statement::Impl { methods, .. } => Some(methods.as_slice()),
        _ => None,
    }
}

#[cfg(test)]
fn dependency_matches_unit(dependency: &str, unit_key: &str) -> bool {
    dependency == unit_key
        || dependency
            == unit_key
                .rsplit_once('.')
                .map(|(_, suffix)| suffix)
                .unwrap_or_default()
        || dependency
            == unit_key
                .rsplit_once('#')
                .map(|(_, suffix)| suffix)
                .unwrap_or_default()
}

fn collect_statement_dependencies(statement: &Statement, deps: &mut Vec<String>) {
    match statement {
        Statement::Let { value, .. } => {
            if let Some(value) = value {
                collect_expression_dependencies(value, deps);
            }
        }
        Statement::Assignment { target, value, .. } => {
            if let Some(name) = target.binding_name() {
                deps.push(name.to_string());
            }
            if let crate::parser::ast::AssignmentTarget::Index { target, index } = target {
                collect_expression_dependencies(target, deps);
                collect_expression_dependencies(index, deps);
            }
            collect_expression_dependencies(value, deps);
        }
        Statement::Function { body, params, .. } => {
            for (_, data_type) in params {
                collect_type_dependencies(data_type, deps);
            }
            for statement in body {
                collect_statement_dependencies(statement, deps);
            }
        }
        Statement::Return(expr) => {
            if let Some(expr) = expr {
                collect_expression_dependencies(expr, deps);
            }
        }
        Statement::If {
            condition,
            then_branch,
            else_branch,
        } => {
            collect_expression_dependencies(condition, deps);
            for statement in then_branch {
                collect_statement_dependencies(statement, deps);
            }
            if let Some(branch) = else_branch {
                for statement in branch {
                    collect_statement_dependencies(statement, deps);
                }
            }
        }
        Statement::While { condition, body } => {
            collect_expression_dependencies(condition, deps);
            for statement in body {
                collect_statement_dependencies(statement, deps);
            }
        }
        Statement::For { iterable, body, .. } | Statement::Find { iterable, body, .. } => {
            collect_expression_dependencies(iterable, deps);
            for statement in body {
                collect_statement_dependencies(statement, deps);
            }
        }
        Statement::Expression(expr) | Statement::Drop { value: expr } => {
            collect_expression_dependencies(expr, deps);
        }
        Statement::Move { target, value } => {
            deps.push(target.clone());
            collect_expression_dependencies(value, deps);
        }
        Statement::Match {
            value,
            cases,
            default,
        } => {
            collect_expression_dependencies(value, deps);
            for (case, statements) in cases {
                collect_expression_dependencies(case, deps);
                for statement in statements {
                    collect_statement_dependencies(statement, deps);
                }
            }
            for statement in default {
                collect_statement_dependencies(statement, deps);
            }
        }
        Statement::Type { fields, .. }
        | Statement::Class {
            methods: fields, ..
        }
        | Statement::Code {
            methods: fields, ..
        }
        | Statement::Unsafe { body: fields }
        | Statement::Module { body: fields, .. }
        | Statement::DmireTable { body: fields, .. }
        | Statement::DmireColumn { body: fields, .. }
        | Statement::Impl {
            methods: fields, ..
        } => {
            for statement in fields {
                collect_statement_dependencies(statement, deps);
            }
        }
        Statement::ExternFunction {
            lib_name,
            params,
            return_type,
            ..
        } => {
            deps.push(lib_name.clone());
            for (_, data_type) in params {
                collect_type_dependencies(data_type, deps);
            }
            collect_type_dependencies(return_type, deps);
        }
        Statement::Enum { variants, .. } => {
            for variant in variants {
                for data_type in &variant.data_types {
                    collect_type_dependencies(data_type, deps);
                }
            }
        }
        Statement::Query {
            bindings,
            ops,
            joins,
            table,
            ..
        } => {
            deps.push(table.clone());
            for binding in bindings {
                deps.push(binding.column.clone());
            }
            for join in joins {
                deps.push(join.right_table.clone());
                deps.push(join.left_column.clone());
                deps.push(join.right_column.clone());
            }
            for op in ops {
                match op {
                    crate::parser::ast::QueryOp::Insert { assigns }
                    | crate::parser::ast::QueryOp::Update { assigns, .. } => {
                        for (_, expr) in assigns {
                            collect_expression_dependencies(expr, deps);
                        }
                    }
                    crate::parser::ast::QueryOp::Delete { condition } => {
                        collect_expression_dependencies(condition, deps);
                    }
                    crate::parser::ast::QueryOp::Get(get) => {
                        deps.push(get.target.clone());
                        collect_expression_dependencies(&get.condition, deps);
                        for statement in &get.body {
                            collect_statement_dependencies(statement, deps);
                        }
                    }
                    crate::parser::ast::QueryOp::Export { path }
                    | crate::parser::ast::QueryOp::Import { path } => deps.push(path.clone()),
                }
            }
        }
        Statement::Asm { instructions } => {
            for (_, expr) in instructions {
                collect_expression_dependencies(expr, deps);
            }
        }
        Statement::Use { path, items, .. } => {
            deps.push(path.clone());
            if let Some(items) = items {
                deps.extend(items.iter().cloned());
            }
        }
        Statement::ExternLib { name, path } => {
            deps.push(name.clone());
            deps.push(path.clone());
        }
        Statement::Skill { methods, .. } | Statement::Trait { methods, .. } => {
            for method in methods {
                deps.push(method.name.clone());
                for (_, data_type) in &method.params {
                    collect_type_dependencies(data_type, deps);
                }
                collect_type_dependencies(&method.return_type, deps);
            }
        }
        Statement::DmireDlist { data, .. } => {
            for expr in data {
                collect_expression_dependencies(expr, deps);
            }
        }
        Statement::Break | Statement::Continue | Statement::AddLib { .. } => {}
    }
}

fn collect_expression_dependencies(expression: &Expression, deps: &mut Vec<String>) {
    match expression {
        Expression::Identifier(ident) => deps.push(ident.name.clone()),
        Expression::Call { name, args, .. } => {
            deps.push(name.clone());
            if let Some((_, member)) = name.rsplit_once('.') {
                deps.push(member.to_string());
            }
            for arg in args {
                collect_expression_dependencies(arg, deps);
            }
        }
        Expression::MemberAccess { target, member, .. } => {
            deps.push(member.clone());
            collect_expression_dependencies(target, deps);
        }
        Expression::BinaryOp { left, right, .. } => {
            collect_expression_dependencies(left, deps);
            collect_expression_dependencies(right, deps);
        }
        Expression::UnaryOp { operand, .. }
        | Expression::Reference { expr: operand, .. }
        | Expression::Dereference { expr: operand, .. }
        | Expression::Box { value: operand, .. } => collect_expression_dependencies(operand, deps),
        Expression::NamedArg { name, value, .. } => {
            deps.push(name.clone());
            collect_expression_dependencies(value, deps);
        }
        Expression::List { elements, .. } | Expression::Tuple { elements, .. } => {
            for element in elements {
                collect_expression_dependencies(element, deps);
            }
        }
        Expression::Dict { entries, .. } => {
            for (key, value) in entries {
                collect_expression_dependencies(key, deps);
                collect_expression_dependencies(value, deps);
            }
        }
        Expression::Index { target, index, .. } => {
            collect_expression_dependencies(target, deps);
            collect_expression_dependencies(index, deps);
        }
        Expression::Closure {
            params,
            body,
            return_type,
            ..
        } => {
            for (_, data_type) in params {
                collect_type_dependencies(data_type, deps);
            }
            collect_type_dependencies(return_type, deps);
            for statement in body {
                collect_statement_dependencies(statement, deps);
            }
        }
        Expression::Pipeline { input, stage, .. } => {
            collect_expression_dependencies(input, deps);
            collect_expression_dependencies(stage, deps);
        }
        Expression::Match {
            value,
            cases,
            default,
            ..
        } => {
            collect_expression_dependencies(value, deps);
            for (case, expr) in cases {
                collect_expression_dependencies(case, deps);
                collect_expression_dependencies(expr, deps);
            }
            collect_expression_dependencies(default, deps);
        }
        Expression::EnumVariantPath {
            enum_name,
            variant_name,
            ..
        } => {
            deps.push(enum_name.clone());
            deps.push(variant_name.clone());
        }
        Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads,
            ..
        } => {
            deps.push(enum_name.clone());
            deps.push(variant_name.clone());
            for payload in payloads {
                collect_expression_dependencies(payload, deps);
            }
        }
        Expression::Literal(_) => {}
    }
}

fn collect_type_dependencies(data_type: &crate::parser::ast::DataType, deps: &mut Vec<String>) {
    match data_type {
        crate::parser::ast::DataType::StructNamed(name)
        | crate::parser::ast::DataType::EnumNamed(name) => deps.push(name.clone()),
        crate::parser::ast::DataType::DynTrait { trait_name } => deps.push(trait_name.clone()),
        crate::parser::ast::DataType::Vector { element_type, .. }
        | crate::parser::ast::DataType::Slice { element_type }
        | crate::parser::ast::DataType::Result { ok: element_type } => {
            collect_type_dependencies(element_type, deps);
        }
        crate::parser::ast::DataType::Map {
            key_type,
            value_type,
        } => {
            collect_type_dependencies(key_type, deps);
            collect_type_dependencies(value_type, deps);
        }
        crate::parser::ast::DataType::Array { element_type, .. } => {
            collect_type_dependencies(element_type, deps);
        }
        _ => {}
    }
}

fn stable_statement_hash(statement: &Statement) -> u64 {
    let mut hasher = FxHasher::new();
    hash_statement(statement, &mut hasher);
    hasher.finish()
}

fn hash_statement(statement: &Statement, hasher: &mut FxHasher) {
    match statement {
        Statement::Let {
            name,
            data_type,
            value,
            is_constant,
            is_mutable,
            is_static,
            visibility,
        } => {
            hasher.write_u8(0);
            name.hash(hasher);
            hash_data_type(data_type, hasher);
            hash_option_expr(value, hasher);
            is_constant.hash(hasher);
            is_mutable.hash(hasher);
            is_static.hash(hasher);
            hash_visibility(*visibility, hasher);
        }
        Statement::Assignment {
            target,
            value,
            is_mutable,
        } => {
            hasher.write_u8(1);
            hash_assignment_target(target, hasher);
            hash_expression(value, hasher);
            is_mutable.hash(hasher);
        }
        Statement::Function {
            name,
            params,
            body,
            return_type,
            visibility,
            is_method,
        } => {
            hasher.write_u8(2);
            name.hash(hasher);
            hash_params(params, hasher);
            hash_statements(body, hasher);
            hash_data_type(return_type, hasher);
            hash_visibility(*visibility, hasher);
            is_method.hash(hasher);
        }
        Statement::Return(expr) => {
            hasher.write_u8(3);
            hash_option_expr(expr, hasher);
        }
        Statement::If {
            condition,
            then_branch,
            else_branch,
        } => {
            hasher.write_u8(4);
            hash_expression(condition, hasher);
            hash_statements(then_branch, hasher);
            hash_optional_statements(else_branch, hasher);
        }
        Statement::While { condition, body } => {
            hasher.write_u8(5);
            hash_expression(condition, hasher);
            hash_statements(body, hasher);
        }
        Statement::For {
            variable,
            index,
            iterable,
            body,
        } => {
            hasher.write_u8(6);
            variable.hash(hasher);
            index.hash(hasher);
            hash_expression(iterable, hasher);
            hash_statements(body, hasher);
        }
        Statement::Expression(expr) => {
            hasher.write_u8(7);
            hash_expression(expr, hasher);
        }
        Statement::Break => hasher.write_u8(8),
        Statement::Continue => hasher.write_u8(9),
        Statement::Find {
            variable,
            iterable,
            body,
        } => {
            hasher.write_u8(10);
            variable.hash(hasher);
            hash_expression(iterable, hasher);
            hash_statements(body, hasher);
        }
        Statement::Match {
            value,
            cases,
            default,
        } => {
            hasher.write_u8(11);
            hash_expression(value, hasher);
            cases.len().hash(hasher);
            for (case, body) in cases {
                hash_expression(case, hasher);
                hash_statements(body, hasher);
            }
            hash_statements(default, hasher);
        }
        Statement::Type {
            name,
            parent,
            fields,
        } => {
            hasher.write_u8(12);
            name.hash(hasher);
            parent.hash(hasher);
            hash_statements(fields, hasher);
        }
        Statement::Skill { name, methods } => {
            hasher.write_u8(13);
            name.hash(hasher);
            hash_trait_methods(methods, hasher);
        }
        Statement::Code {
            trait_name,
            type_name,
            methods,
        } => {
            hasher.write_u8(14);
            trait_name.hash(hasher);
            type_name.hash(hasher);
            hash_statements(methods, hasher);
        }
        Statement::Class {
            name,
            parent,
            methods,
        } => {
            hasher.write_u8(15);
            name.hash(hasher);
            parent.hash(hasher);
            hash_statements(methods, hasher);
        }
        Statement::Trait { name, methods } => {
            hasher.write_u8(16);
            name.hash(hasher);
            hash_trait_methods(methods, hasher);
        }
        Statement::Impl {
            trait_name,
            type_name,
            methods,
        } => {
            hasher.write_u8(17);
            trait_name.hash(hasher);
            type_name.hash(hasher);
            hash_statements(methods, hasher);
        }
        Statement::ExternLib { name, path } => {
            hasher.write_u8(18);
            name.hash(hasher);
            path.hash(hasher);
        }
        Statement::ExternFunction {
            name,
            lib_name,
            params,
            return_type,
        } => {
            hasher.write_u8(19);
            name.hash(hasher);
            lib_name.hash(hasher);
            hash_params(params, hasher);
            hash_data_type(return_type, hasher);
        }
        Statement::Unsafe { body } => {
            hasher.write_u8(20);
            hash_statements(body, hasher);
        }
        Statement::Asm { instructions } => {
            hasher.write_u8(21);
            instructions.len().hash(hasher);
            for (name, expr) in instructions {
                name.hash(hasher);
                hash_expression(expr, hasher);
            }
        }
        Statement::AddLib { path } => {
            hasher.write_u8(22);
            path.hash(hasher);
        }
        Statement::Use {
            path,
            alias,
            items,
            is_local,
        } => {
            hasher.write_u8(23);
            path.hash(hasher);
            alias.hash(hasher);
            items.hash(hasher);
            is_local.hash(hasher);
        }
        Statement::Module { name, body } => {
            hasher.write_u8(24);
            name.hash(hasher);
            hash_statements(body, hasher);
        }
        Statement::Drop { value } => {
            hasher.write_u8(25);
            hash_expression(value, hasher);
        }
        Statement::Move { target, value } => {
            hasher.write_u8(26);
            target.hash(hasher);
            hash_expression(value, hasher);
        }
        Statement::Enum { name, variants } => {
            hasher.write_u8(27);
            name.hash(hasher);
            hash_enum_variants(variants, hasher);
        }
        Statement::DmireTable {
            name,
            columns,
            body,
        } => {
            hasher.write_u8(28);
            name.hash(hasher);
            columns.hash(hasher);
            hash_statements(body, hasher);
        }
        Statement::DmireColumn {
            name,
            col_type,
            body,
        } => {
            hasher.write_u8(29);
            name.hash(hasher);
            col_type.hash(hasher);
            hash_statements(body, hasher);
        }
        Statement::DmireDlist { index, data } => {
            hasher.write_u8(30);
            index.hash(hasher);
            hash_expressions(data, hasher);
        }
        Statement::Query {
            table,
            bindings,
            ops,
            joins,
            group_by,
        } => {
            hasher.write_u8(31);
            table.hash(hasher);
            hash_query_bindings(bindings, hasher);
            hash_query_ops(ops, hasher);
            hash_query_joins(joins, hasher);
            hash_query_group(group_by.as_ref(), hasher);
        }
    }
}

fn hash_expression(expr: &Expression, hasher: &mut FxHasher) {
    match expr {
        Expression::Literal(lit) => {
            hasher.write_u8(0);
            hash_literal(lit, hasher);
        }
        Expression::Identifier(ident) => {
            hasher.write_u8(1);
            hash_identifier(ident, hasher);
        }
        Expression::BinaryOp {
            operator,
            left,
            right,
            data_type,
        } => {
            hasher.write_u8(2);
            operator.hash(hasher);
            hash_expression(left, hasher);
            hash_expression(right, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::UnaryOp {
            operator,
            operand,
            data_type,
        } => {
            hasher.write_u8(3);
            operator.hash(hasher);
            hash_expression(operand, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::NamedArg {
            name,
            value,
            data_type,
        } => {
            hasher.write_u8(4);
            name.hash(hasher);
            hash_expression(value, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Call {
            name,
            args,
            data_type,
        } => {
            hasher.write_u8(5);
            name.hash(hasher);
            hash_expressions(args, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::List {
            elements,
            element_type,
            data_type,
        } => {
            hasher.write_u8(6);
            hash_expressions(elements, hasher);
            hash_data_type(element_type, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Dict {
            entries,
            key_type,
            value_type,
            data_type,
        } => {
            hasher.write_u8(7);
            entries.len().hash(hasher);
            for (k, v) in entries {
                hash_expression(k, hasher);
                hash_expression(v, hasher);
            }
            hash_data_type(key_type, hasher);
            hash_data_type(value_type, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Tuple {
            elements,
            data_type,
        } => {
            hasher.write_u8(8);
            hash_expressions(elements, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Index {
            target,
            index,
            data_type,
        } => {
            hasher.write_u8(9);
            hash_expression(target, hasher);
            hash_expression(index, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::MemberAccess {
            target,
            member,
            data_type,
        } => {
            hasher.write_u8(10);
            hash_expression(target, hasher);
            member.hash(hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Closure {
            params,
            body,
            return_type,
            capture,
        } => {
            hasher.write_u8(11);
            hash_params(params, hasher);
            hash_statements(body, hasher);
            hash_data_type(return_type, hasher);
            capture.len().hash(hasher);
            for (name, value) in capture {
                name.hash(hasher);
                hash_mire_value(value, hasher);
            }
        }
        Expression::Reference {
            expr,
            is_mutable,
            data_type,
            referenced_type,
        } => {
            hasher.write_u8(12);
            hash_expression(expr, hasher);
            is_mutable.hash(hasher);
            hash_data_type(data_type, hasher);
            hash_data_type(referenced_type, hasher);
        }
        Expression::Dereference { expr, data_type } => {
            hasher.write_u8(13);
            hash_expression(expr, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Box { value, data_type } => {
            hasher.write_u8(14);
            hash_expression(value, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Pipeline {
            input,
            stage,
            safe,
            data_type,
        } => {
            hasher.write_u8(15);
            hash_expression(input, hasher);
            hash_expression(stage, hasher);
            safe.hash(hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::Match {
            value,
            cases,
            default,
            data_type,
        } => {
            hasher.write_u8(16);
            hash_expression(value, hasher);
            cases.len().hash(hasher);
            for (a, b) in cases {
                hash_expression(a, hasher);
                hash_expression(b, hasher);
            }
            hash_expression(default, hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::EnumVariantPath {
            enum_name,
            variant_name,
            data_type,
        } => {
            hasher.write_u8(17);
            enum_name.hash(hasher);
            variant_name.hash(hasher);
            hash_data_type(data_type, hasher);
        }
        Expression::EnumVariant {
            enum_name,
            variant_name,
            payloads,
            data_type,
        } => {
            hasher.write_u8(18);
            enum_name.hash(hasher);
            variant_name.hash(hasher);
            hash_expressions(payloads, hasher);
            hash_data_type(data_type, hasher);
        }
    }
}

fn hash_literal(lit: &Literal, hasher: &mut FxHasher) {
    match lit {
        Literal::Int(value) => {
            hasher.write_u8(0);
            value.hash(hasher);
        }
        Literal::Float(value) => {
            hasher.write_u8(1);
            value.to_bits().hash(hasher);
        }
        Literal::Char(value) => {
            hasher.write_u8(2);
            value.hash(hasher);
        }
        Literal::Str(value) => {
            hasher.write_u8(3);
            value.hash(hasher);
        }
        Literal::Bool(value) => {
            hasher.write_u8(4);
            value.hash(hasher);
        }
        Literal::None => hasher.write_u8(5),
        Literal::List(values) => {
            hasher.write_u8(6);
            hash_expressions(values, hasher);
        }
        Literal::Dict(values) => {
            hasher.write_u8(7);
            values.len().hash(hasher);
            for ((k, v), dt) in values {
                hash_expression(k, hasher);
                hash_expression(v, hasher);
                hash_data_type(dt, hasher);
            }
        }
        Literal::Tuple(values) => {
            hasher.write_u8(8);
            hash_expressions(values, hasher);
        }
    }
}

fn hash_data_type(data_type: &DataType, hasher: &mut FxHasher) {
    match data_type {
        DataType::I8 => hasher.write_u8(0),
        DataType::I16 => hasher.write_u8(1),
        DataType::I32 => hasher.write_u8(2),
        DataType::I64 => hasher.write_u8(3),
        DataType::U8 => hasher.write_u8(4),
        DataType::U16 => hasher.write_u8(5),
        DataType::U32 => hasher.write_u8(6),
        DataType::U64 => hasher.write_u8(7),
        DataType::F32 => hasher.write_u8(8),
        DataType::F64 => hasher.write_u8(9),
        DataType::Char => hasher.write_u8(41),
        DataType::Str => hasher.write_u8(10),
        DataType::Bool => hasher.write_u8(11),
        DataType::None => hasher.write_u8(12),
        DataType::List => hasher.write_u8(13),
        DataType::Vector {
            element_type,
            dynamic,
        } => {
            hasher.write_u8(14);
            hash_data_type(element_type, hasher);
            dynamic.hash(hasher);
        }
        DataType::Dict => hasher.write_u8(15),
        DataType::Map {
            key_type,
            value_type,
        } => {
            hasher.write_u8(16);
            hash_data_type(key_type, hasher);
            hash_data_type(value_type, hasher);
        }
        DataType::Anything => hasher.write_u8(17),
        DataType::Function => hasher.write_u8(18),
        DataType::Struct => hasher.write_u8(19),
        DataType::StructNamed(name) => {
            hasher.write_u8(20);
            name.hash(hasher);
        }
        DataType::Db => hasher.write_u8(21),
        DataType::Tuple => hasher.write_u8(22),
        DataType::Set => hasher.write_u8(23),
        DataType::Datetime => hasher.write_u8(24),
        DataType::Unknown => hasher.write_u8(25),
        DataType::Ref { inner } => {
            hasher.write_u8(26);
            hash_data_type(inner, hasher);
        }
        DataType::RefMut { inner } => {
            hasher.write_u8(27);
            hash_data_type(inner, hasher);
        }
        DataType::Box => hasher.write_u8(28),
        DataType::Enum => hasher.write_u8(29),
        DataType::EnumNamed(name) => {
            hasher.write_u8(30);
            name.hash(hasher);
        }
        DataType::DynTrait { trait_name } => {
            hasher.write_u8(31);
            trait_name.hash(hasher);
        }
        DataType::Array { element_type, size } => {
            hasher.write_u8(32);
            hash_data_type(element_type, hasher);
            size.hash(hasher);
        }
        DataType::Slice { element_type } => {
            hasher.write_u8(33);
            hash_data_type(element_type, hasher);
        }
        DataType::Result { ok } => {
            hasher.write_u8(34);
            hash_data_type(ok, hasher);
        }
    }
}

fn hash_assignment_target(target: &AssignmentTarget, hasher: &mut FxHasher) {
    match target {
        AssignmentTarget::Variable(name) => {
            hasher.write_u8(0);
            name.hash(hasher);
        }
        AssignmentTarget::Field(name) => {
            hasher.write_u8(1);
            name.hash(hasher);
        }
        AssignmentTarget::Index { target, index } => {
            hasher.write_u8(2);
            hash_expression(target, hasher);
            hash_expression(index, hasher);
        }
    }
}

fn hash_identifier(identifier: &Identifier, hasher: &mut FxHasher) {
    identifier.name.hash(hasher);
    hash_data_type(&identifier.data_type, hasher);
    identifier.line.hash(hasher);
    identifier.column.hash(hasher);
}

fn hash_visibility(visibility: Visibility, hasher: &mut FxHasher) {
    match visibility {
        Visibility::Public => hasher.write_u8(0),
        Visibility::Private => hasher.write_u8(1),
        Visibility::Protected => hasher.write_u8(2),
    }
}

fn hash_trait_methods(methods: &[TraitMethodSig], hasher: &mut FxHasher) {
    methods.len().hash(hasher);
    for method in methods {
        method.name.hash(hasher);
        hash_params(&method.params, hasher);
        hash_data_type(&method.return_type, hasher);
    }
}

fn hash_enum_variants(variants: &[EnumVariantDef], hasher: &mut FxHasher) {
    variants.len().hash(hasher);
    for variant in variants {
        variant.enum_name.hash(hasher);
        variant.name.hash(hasher);
        variant.payload_names.hash(hasher);
        hash_data_types(&variant.data_types, hasher);
    }
}

fn hash_query_bindings(bindings: &[QueryBinding], hasher: &mut FxHasher) {
    bindings.len().hash(hasher);
    for binding in bindings {
        binding.target.hash(hasher);
        binding.alias.hash(hasher);
        binding.column.hash(hasher);
    }
}

fn hash_query_ops(ops: &[QueryOp], hasher: &mut FxHasher) {
    ops.len().hash(hasher);
    for op in ops {
        match op {
            QueryOp::Insert { assigns } => {
                hasher.write_u8(0);
                hash_string_expr_pairs(assigns, hasher);
            }
            QueryOp::Update { condition, assigns } => {
                hasher.write_u8(1);
                hash_expression(condition, hasher);
                hash_string_expr_pairs(assigns, hasher);
            }
            QueryOp::Delete { condition } => {
                hasher.write_u8(2);
                hash_expression(condition, hasher);
            }
            QueryOp::Get(QueryGet {
                target,
                condition,
                body,
            }) => {
                hasher.write_u8(3);
                target.hash(hasher);
                hash_expression(condition, hasher);
                hash_statements(body, hasher);
            }
            QueryOp::Export { path } => {
                hasher.write_u8(4);
                path.hash(hasher);
            }
            QueryOp::Import { path } => {
                hasher.write_u8(5);
                path.hash(hasher);
            }
        }
    }
}

fn hash_query_joins(joins: &[QueryJoin], hasher: &mut FxHasher) {
    joins.len().hash(hasher);
    for join in joins {
        join.right_table.hash(hasher);
        join.left_column.hash(hasher);
        join.right_column.hash(hasher);
    }
}

fn hash_query_group(group: Option<&QueryGroup>, hasher: &mut FxHasher) {
    match group {
        Some(group) => {
            hasher.write_u8(1);
            group.column.hash(hasher);
        }
        None => hasher.write_u8(0),
    }
}

fn hash_mire_value(value: &MireValue, hasher: &mut FxHasher) {
    match value {
        MireValue::I8(v) => {
            hasher.write_u8(0);
            v.hash(hasher);
        }
        MireValue::I16(v) => {
            hasher.write_u8(1);
            v.hash(hasher);
        }
        MireValue::I32(v) => {
            hasher.write_u8(2);
            v.hash(hasher);
        }
        MireValue::I64(v) => {
            hasher.write_u8(3);
            v.hash(hasher);
        }
        MireValue::U8(v) => {
            hasher.write_u8(4);
            v.hash(hasher);
        }
        MireValue::U16(v) => {
            hasher.write_u8(5);
            v.hash(hasher);
        }
        MireValue::U32(v) => {
            hasher.write_u8(6);
            v.hash(hasher);
        }
        MireValue::U64(v) => {
            hasher.write_u8(7);
            v.hash(hasher);
        }
        MireValue::Float(v) => {
            hasher.write_u8(8);
            v.to_bits().hash(hasher);
        }
        MireValue::F32(v) => {
            hasher.write_u8(9);
            v.to_bits().hash(hasher);
        }
        MireValue::F64(v) => {
            hasher.write_u8(10);
            v.to_bits().hash(hasher);
        }
        MireValue::Str(v) => {
            hasher.write_u8(11);
            v.hash(hasher);
        }
        MireValue::Bool(v) => {
            hasher.write_u8(12);
            v.hash(hasher);
        }
        MireValue::None => hasher.write_u8(13),
        MireValue::List(values) => {
            hasher.write_u8(14);
            values.len().hash(hasher);
            for value in values {
                hash_mire_value(value, hasher);
            }
        }
        MireValue::Dict(values) => {
            hasher.write_u8(15);
            values.len().hash(hasher);
            for ((k, v), dt) in values {
                hash_mire_value(k, hasher);
                hash_mire_value(v, hasher);
                hash_data_type(dt, hasher);
            }
        }
        MireValue::Tuple(values) => {
            hasher.write_u8(16);
            values.len().hash(hasher);
            for value in values {
                hash_mire_value(value, hasher);
            }
        }
        MireValue::Function(function) => {
            hasher.write_u8(17);
            hash_function_def(function, hasher);
        }
        MireValue::Builtinfn(name) => {
            hasher.write_u8(18);
            name.hash(hasher);
        }
        MireValue::Object {
            class_name,
            parent,
            fields,
            methods,
        } => {
            hasher.write_u8(19);
            class_name.hash(hasher);
            parent.hash(hasher);
            fields.len().hash(hasher);
            for ((name, value), dt) in fields {
                name.hash(hasher);
                hash_mire_value(value, hasher);
                hash_data_type(dt, hasher);
            }
            hash_function_defs(methods, hasher);
        }
        MireValue::Trait { name, methods } => {
            hasher.write_u8(20);
            name.hash(hasher);
            hash_trait_methods(methods, hasher);
        }
        MireValue::Instance {
            class_name,
            fields,
            methods,
        } => {
            hasher.write_u8(21);
            class_name.hash(hasher);
            fields.len().hash(hasher);
            for ((name, value), dt) in fields {
                name.hash(hasher);
                hash_mire_value(value, hasher);
                hash_data_type(dt, hasher);
            }
            hash_function_defs(methods, hasher);
        }
        MireValue::Ref { value, is_mutable } => {
            hasher.write_u8(22);
            hash_mire_value(value, hasher);
            is_mutable.hash(hasher);
        }
        MireValue::Box { value } => {
            hasher.write_u8(23);
            hash_mire_value(value, hasher);
        }
        MireValue::Array { elements, size } => {
            hasher.write_u8(24);
            size.hash(hasher);
            elements.len().hash(hasher);
            for value in elements {
                hash_mire_value(value, hasher);
            }
        }
        MireValue::Slice { elements } => {
            hasher.write_u8(25);
            elements.len().hash(hasher);
            for value in elements {
                hash_mire_value(value, hasher);
            }
        }
        MireValue::EnumVariant {
            enum_name,
            variant_name,
            data,
        } => {
            hasher.write_u8(26);
            enum_name.hash(hasher);
            variant_name.hash(hasher);
            data.len().hash(hasher);
            for value in data {
                hash_mire_value(value, hasher);
            }
        }
    }
}

fn hash_function_def(function: &FunctionDef, hasher: &mut FxHasher) {
    function.name.hash(hasher);
    hash_params(&function.params, hasher);
    hash_statements(function.body.as_ref(), hasher);
    hash_data_type(&function.return_type, hasher);
    function.is_method.hash(hasher);
    function.capture.len().hash(hasher);
    for (name, value) in &function.capture {
        name.hash(hasher);
        hash_mire_value(value, hasher);
    }
}

fn hash_function_defs(functions: &[FunctionDef], hasher: &mut FxHasher) {
    functions.len().hash(hasher);
    for function in functions {
        hash_function_def(function, hasher);
    }
}

fn hash_params(params: &[(String, DataType)], hasher: &mut FxHasher) {
    params.len().hash(hasher);
    for (name, dt) in params {
        name.hash(hasher);
        hash_data_type(dt, hasher);
    }
}

fn hash_data_types(types: &[DataType], hasher: &mut FxHasher) {
    types.len().hash(hasher);
    for data_type in types {
        hash_data_type(data_type, hasher);
    }
}

fn hash_statements(statements: &[Statement], hasher: &mut FxHasher) {
    statements.len().hash(hasher);
    for statement in statements {
        hash_statement(statement, hasher);
    }
}

fn hash_optional_statements(statements: &Option<Vec<Statement>>, hasher: &mut FxHasher) {
    match statements {
        Some(statements) => {
            hasher.write_u8(1);
            hash_statements(statements, hasher);
        }
        None => hasher.write_u8(0),
    }
}

fn hash_expressions(expressions: &[Expression], hasher: &mut FxHasher) {
    expressions.len().hash(hasher);
    for expr in expressions {
        hash_expression(expr, hasher);
    }
}

fn hash_option_expr(expr: &Option<Expression>, hasher: &mut FxHasher) {
    match expr {
        Some(expr) => {
            hasher.write_u8(1);
            hash_expression(expr, hasher);
        }
        None => hasher.write_u8(0),
    }
}

fn hash_string_expr_pairs(pairs: &[(String, Expression)], hasher: &mut FxHasher) {
    pairs.len().hash(hasher);
    for (name, expr) in pairs {
        name.hash(hasher);
        hash_expression(expr, hasher);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::parser::ast::{DataType, Expression, Identifier, Literal, Visibility};
    use crate::parser::parse;

    fn demo_program(name: &str) -> Program {
        Program {
            statements: vec![Statement::Function {
                name: name.to_string(),
                params: Vec::new(),
                body: Vec::new(),
                return_type: crate::parser::ast::DataType::None,
                visibility: crate::parser::ast::Visibility::Public,
                is_method: false,
            }],
        }
    }

    #[test]
    fn binary_cache_roundtrips_parsed_and_analysis_entries() {
        let root = std::env::temp_dir().join(format!("mire_cache_test_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(16),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");
        cache
            .store_file(
                &source_path,
                CachedParsedFile {
                    hash: 1,
                    program: demo_program("main"),
                    exports: vec!["main".to_string()],
                    local_imports: Vec::new(),
                },
            )
            .expect("store file");
        cache
            .store_analysis(&source_path, 42, &demo_program("typed_main"))
            .expect("store analysis");
        cache.save().expect("save");

        let mut reloaded =
            IncrementalCache::load_with_settings(&source_path, settings).expect("reload");
        let parsed = reloaded
            .cached_file(&source_path, 1)
            .expect("cached parsed file");
        assert_eq!(parsed.exports, vec!["main".to_string()]);
        let analyzed = reloaded
            .cached_analysis(&source_path, 42)
            .expect("cached analysis");
        match analyzed {
            CachedAnalysis::Success(program) => assert_eq!(program.statements.len(), 1),
            CachedAnalysis::Error(err) => panic!("unexpected cached error: {err}"),
        }
    }

    #[cfg(unix)]
    #[test]
    fn binary_cache_uses_memory_mapping_until_mutated() {
        let root = std::env::temp_dir().join(format!("mire_cache_mmap_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(16),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");
        cache
            .store_analysis(&source_path, 42, &demo_program("typed_main"))
            .expect("store analysis");
        cache.save().expect("save");

        let mut reloaded =
            IncrementalCache::load_with_settings(&source_path, settings).expect("reload");
        assert!(reloaded.blob_store.is_memory_mapped());
        assert!(reloaded.cached_analysis(&source_path, 42).is_some());

        reloaded
            .store_analysis(&source_path, 43, &demo_program("typed_main_v2"))
            .expect("store second analysis");
        assert!(!reloaded.blob_store.is_memory_mapped());
    }

    #[test]
    fn lru_prunes_when_max_units_is_reached() {
        let root = std::env::temp_dir().join(format!("mire_cache_lru_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(1),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");
        cache
            .store_file(
                &source_path,
                CachedParsedFile {
                    hash: 1,
                    program: demo_program("main"),
                    exports: vec!["main".to_string()],
                    local_imports: Vec::new(),
                },
            )
            .expect("store file");
        cache
            .store_analysis(&source_path, 7, &demo_program("analysis"))
            .expect("store analysis");
        assert!(cache.db.files.len() + cache.db.analyses.len() <= 1);
        assert!(cache.metrics().evictions >= 1);
    }

    #[test]
    fn blob_store_compacts_when_sparse_after_overwrites() {
        let root = std::env::temp_dir().join(format!("mire_cache_compact_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(256),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");

        for i in 0..32 {
            let function_name = format!("main_{}", i);
            cache
                .store_analysis(&source_path, 7, &demo_program(&function_name))
                .expect("store analysis overwrite");
        }

        let blob_len = cache.blob_store.bytes().len();
        let active_len = cache
            .db
            .analyses
            .values()
            .next()
            .map(|entry| entry.blob_len as usize)
            .unwrap_or(0);

        assert!(blob_len <= active_len.saturating_mul(2));
    }

    #[test]
    fn blob_store_compaction_preserves_offsets_inside_merged_ranges() {
        let root = std::env::temp_dir().join(format!("mire_cache_compact_ranges_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(256),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");

        cache
            .store_analysis(&source_path, 1, &demo_program("a"))
            .expect("store analysis a");
        cache
            .store_analysis(&source_path, 2, &demo_program("b"))
            .expect("store analysis b");

        // Keep entry 2 and force a sparse blob by dropping the first entry.
        let key1 = analysis_cache_key(&source_path, 1);
        cache.db.analyses.remove(&key1);
        cache.maybe_compact_blob_store();

        let cached = cache
            .cached_analysis(&source_path, 2)
            .expect("analysis 2 should survive compaction");
        match cached {
            CachedAnalysis::Success(program) => assert_eq!(program.statements.len(), 1),
            CachedAnalysis::Error(err) => panic!("unexpected cached error: {err}"),
        }
    }

    #[test]
    fn cache_metrics_track_file_and_analysis_hits_and_misses() {
        let root = std::env::temp_dir().join(format!("mire_cache_metrics_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(16),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");
        cache
            .store_file(
                &source_path,
                CachedParsedFile {
                    hash: 1,
                    program: demo_program("main"),
                    exports: vec!["main".to_string()],
                    local_imports: Vec::new(),
                },
            )
            .expect("store file");
        cache
            .store_analysis(&source_path, 42, &demo_program("typed_main"))
            .expect("store analysis");

        assert!(cache.cached_file(&source_path, 1).is_some());
        assert!(cache.cached_file(&source_path, 2).is_none());
        assert!(cache.cached_analysis(&source_path, 42).is_some());
        assert!(cache.cached_analysis(&source_path, 99).is_none());

        let metrics = cache.metrics();
        assert_eq!(metrics.file_hits, 1);
        assert_eq!(metrics.file_misses, 1);
        assert_eq!(metrics.analysis_hits, 1);
        assert_eq!(metrics.analysis_misses, 1);
    }

    #[test]
    fn binary_cache_roundtrips_analysis_errors() {
        let root = std::env::temp_dir().join(format!("mire_cache_error_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(16),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");
        let error = MireError::new(ErrorKind::Type {
            line: 1,
            column: 1,
            message: "cached type failure".to_string(),
        })
        .with_filename(source_path.display().to_string())
        .with_source("pub fn main: () {}\n".to_string());
        cache
            .store_analysis_error(&source_path, 99, &demo_program("broken"), &error)
            .expect("store error");
        cache.save().expect("save");

        let mut reloaded =
            IncrementalCache::load_with_settings(&source_path, settings).expect("reload");
        let cached = reloaded
            .cached_analysis(&source_path, 99)
            .expect("cached analysis");
        match cached {
            CachedAnalysis::Success(_) => panic!("expected cached error"),
            CachedAnalysis::Error(err) => {
                assert!(matches!(err.kind, ErrorKind::Type { .. }));
                assert!(err.to_string().contains("cached type failure"));
            }
        }
    }

    #[test]
    fn load_with_settings_recovers_from_corrupt_cache_file() {
        let root = std::env::temp_dir().join(format!("mire_cache_corrupt_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let cache_path = cache_file_path(&source_path);
        if let Some(parent) = cache_path.parent() {
            fs::create_dir_all(parent).expect("cache dir");
        }
        fs::write(&cache_path, b"not-a-valid-incremental-cache").expect("write corrupt cache");

        let settings = CacheSettings {
            max_units: Some(16),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");

        assert!(cache.db.files.is_empty());
        assert!(cache.db.analyses.is_empty());
        assert!(cache.db.builds.is_empty());
        assert!(!cache_path.exists(), "corrupt cache file should be removed");

        cache
            .store_analysis(&source_path, 42, &demo_program("typed_main"))
            .expect("store analysis");
        cache.save().expect("save rebuilt cache");

        let mut reloaded =
            IncrementalCache::load_with_settings(&source_path, settings).expect("reload");
        assert!(reloaded.cached_analysis(&source_path, 42).is_some());
    }

    #[test]
    fn invalidation_report_marks_dependents_of_changed_function() {
        let previous = parse(
            "fn helper: () :i64 {\n    return 1\n}\nfn main: () :i64 {\n    return helper()\n}\n",
        )
        .expect("parse previous");
        let current = parse(
            "fn helper: () :i64 {\n    return 2\n}\nfn main: () :i64 {\n    return helper()\n}\n",
        )
        .expect("parse current");

        let report = compute_invalidation_report(
            &analysis_units_for_program(&previous),
            &analysis_units_for_program(&current),
        );

        assert_eq!(report.changed_units, vec!["helper".to_string()]);
        assert!(report.invalidated_units.contains(&"helper".to_string()));
        assert!(report.invalidated_units.contains(&"main".to_string()));
    }

    #[test]
    fn invalidation_report_marks_added_and_removed_units() {
        let previous = parse("fn helper: () :i64 {\n    return 1\n}\n").expect("parse previous");
        let current = parse(
            "fn helper: () :i64 {\n    return 1\n}\nfn main: () :i64 {\n    return helper()\n}\n",
        )
        .expect("parse current");

        let report = compute_invalidation_report(
            &analysis_units_for_program(&previous),
            &analysis_units_for_program(&current),
        );
        assert_eq!(report.added_units, vec!["main".to_string()]);
        assert!(report.invalidated_units.contains(&"main".to_string()));

        let reverse = compute_invalidation_report(
            &analysis_units_for_program(&current),
            &analysis_units_for_program(&previous),
        );
        assert_eq!(reverse.removed_units, vec!["main".to_string()]);
        assert!(reverse.invalidated_units.contains(&"main".to_string()));
    }

    #[test]
    fn invalidation_report_uses_latest_created_not_last_access() {
        let root =
            std::env::temp_dir().join(format!("mire_cache_latest_created_{}", now_epoch_ms()));
        fs::create_dir_all(&root).expect("temp dir");
        let source_path = root.join("main.mire");
        fs::write(&source_path, "pub fn main: () {}\n").expect("source");

        let settings = CacheSettings {
            max_units: Some(32),
            analysis_cache: true,
            compression: false,
        };
        let mut cache = IncrementalCache::load_with_settings(&source_path, settings).expect("load");

        let older =
            parse("fn helper: () :i64 {\n    return 1\n}\nfn main: () :i64 {\n    return helper()\n}\n")
                .expect("parse older");
        cache
            .store_analysis(&source_path, 100, &older)
            .expect("store older analysis");

        std::thread::sleep(std::time::Duration::from_millis(2));

        let newer = parse(
            "fn helper: () :i64 {\n    return 1\n}\nfn main: () :i64 {\n    return helper()\n}\nfn extra: () :i64 {\n    return 7\n}\n",
        )
        .expect("parse newer");
        cache
            .store_analysis(&source_path, 101, &newer)
            .expect("store newer analysis");

        // Touch old fingerprint so its last_access becomes newer than the actual latest snapshot.
        let _ = cache.cached_analysis(&source_path, 100);

        let report = cache
            .analysis_invalidation_report(&source_path, &newer)
            .expect("report");
        assert!(
            report.changed_units.is_empty(),
            "must compare against newest created snapshot, got changed={:?}",
            report.changed_units
        );
        assert!(
            report.added_units.is_empty(),
            "must compare against newest created snapshot, got added={:?}",
            report.added_units
        );
    }

    #[test]
    fn analysis_units_include_nested_children_for_supported_containers() {
        let program = Program {
            statements: vec![
                Statement::Type {
                    name: "PointType".to_string(),
                    parent: None,
                    fields: vec![Statement::Let {
                        name: "x".to_string(),
                        data_type: DataType::I64,
                        value: Some(Expression::Literal(Literal::Int(1))),
                        is_constant: false,
                        is_mutable: false,
                        is_static: false,
                        visibility: Visibility::Public,
                    }],
                },
                Statement::Class {
                    name: "PointClass".to_string(),
                    parent: None,
                    methods: vec![Statement::Function {
                        name: "good".to_string(),
                        params: vec![],
                        body: vec![],
                        return_type: DataType::None,
                        visibility: Visibility::Public,
                        is_method: true,
                    }],
                },
                Statement::Code {
                    trait_name: "Drawable".to_string(),
                    type_name: "PointCode".to_string(),
                    methods: vec![Statement::Function {
                        name: "draw".to_string(),
                        params: vec![],
                        body: vec![],
                        return_type: DataType::None,
                        visibility: Visibility::Public,
                        is_method: true,
                    }],
                },
                Statement::Impl {
                    trait_name: None,
                    type_name: "PointImpl".to_string(),
                    methods: vec![Statement::Function {
                        name: "new".to_string(),
                        params: vec![],
                        body: vec![],
                        return_type: DataType::None,
                        visibility: Visibility::Public,
                        is_method: true,
                    }],
                },
            ],
        };

        let units = analysis_units_for_program(&program);
        let keys: Vec<_> = units.into_iter().map(|unit| unit.unit_key).collect();

        assert!(keys.contains(&"PointType".to_string()));
        assert!(keys.contains(&"PointType#x".to_string()));
        assert!(keys.contains(&"PointClass".to_string()));
        assert!(keys.contains(&"PointClass.good".to_string()));
        assert!(keys.contains(&"code::Drawable::PointCode".to_string()));
        assert!(keys.contains(&"PointCode.draw".to_string()));
        assert!(keys.contains(&"impl::PointImpl".to_string()));
        assert!(keys.contains(&"PointImpl.new".to_string()));
    }

    #[test]
    fn stable_statement_hash_is_deterministic_for_same_statement() {
        let stmt = Statement::Function {
            name: "main".to_string(),
            params: vec![("x".to_string(), DataType::I64)],
            body: vec![Statement::Return(Some(Expression::BinaryOp {
                left: Box::new(Expression::Identifier(Identifier {
                    name: "x".to_string(),
                    data_type: DataType::I64,
                    line: 0,
                    column: 0,
                })),
                operator: "+".to_string(),
                right: Box::new(Expression::Literal(Literal::Int(1))),
                data_type: DataType::I64,
            }))],
            return_type: DataType::I64,
            visibility: Visibility::Public,
            is_method: false,
        };

        let h1 = stable_statement_hash(&stmt);
        let h2 = stable_statement_hash(&stmt);
        assert_eq!(h1, h2);
        assert_ne!(h1, 0);
    }

    #[test]
    fn stable_statement_hash_changes_when_statement_changes() {
        let stmt_a = Statement::Function {
            name: "main".to_string(),
            params: Vec::new(),
            body: vec![Statement::Return(Some(Expression::Literal(Literal::Int(1))))],
            return_type: DataType::I64,
            visibility: Visibility::Public,
            is_method: false,
        };
        let stmt_b = Statement::Function {
            name: "main".to_string(),
            params: Vec::new(),
            body: vec![Statement::Return(Some(Expression::Literal(Literal::Int(2))))],
            return_type: DataType::I64,
            visibility: Visibility::Public,
            is_method: false,
        };

        let h1 = stable_statement_hash(&stmt_a);
        let h2 = stable_statement_hash(&stmt_b);
        assert_ne!(h1, h2);
    }

    fn compute_invalidation_report_naive(
        previous_units: &[AnalysisUnitMetadata],
        current_units: &[AnalysisUnitMetadata],
    ) -> AnalysisInvalidationReport {
        let previous_by_key: HashMap<_, _> = previous_units
            .iter()
            .map(|unit| (unit.unit_key.clone(), unit))
            .collect();
        let current_by_key: HashMap<_, _> = current_units
            .iter()
            .map(|unit| (unit.unit_key.clone(), unit))
            .collect();

        let mut changed_units = Vec::new();
        let mut added_units = Vec::new();
        let mut removed_units = Vec::new();

        for (key, current) in &current_by_key {
            match previous_by_key.get(key) {
                Some(previous) => {
                    if previous.body_hash != current.body_hash
                        || previous.dependencies != current.dependencies
                        || previous.unit_kind != current.unit_kind
                    {
                        changed_units.push(key.clone());
                    }
                }
                None => added_units.push(key.clone()),
            }
        }

        for key in previous_by_key.keys() {
            if !current_by_key.contains_key(key) {
                removed_units.push(key.clone());
            }
        }

        let mut invalidated: HashMap<String, ()> = HashMap::new();
        let mut queue = changed_units.clone();
        queue.extend(added_units.clone());
        queue.extend(removed_units.clone());

        while let Some(unit) = queue.pop() {
            if invalidated.insert(unit.clone(), ()).is_some() {
                continue;
            }

            for current in current_units {
                if current
                    .dependencies
                    .iter()
                    .any(|dep| dependency_matches_unit(dep, &unit))
                    && !invalidated.contains_key(&current.unit_key)
                {
                    queue.push(current.unit_key.clone());
                }
            }
        }

        let mut invalidated_units: Vec<_> = invalidated.into_keys().collect();
        changed_units.sort();
        added_units.sort();
        removed_units.sort();
        invalidated_units.sort();

        AnalysisInvalidationReport {
            changed_units,
            invalidated_units,
            added_units,
            removed_units,
        }
    }

    #[test]
    fn invalidation_report_indexed_matches_naive_behavior() {
        let mut previous = Vec::new();
        let mut current = Vec::new();
        let n = 300usize;

        for i in 0..n {
            let key = format!("Type{i}.run");
            let dep = if i == 0 {
                "seed".to_string()
            } else {
                format!("run{}", i - 1)
            };
            let unit_prev = AnalysisUnitMetadata {
                unit_key: key.clone(),
                unit_kind: AnalysisUnitKind::Function,
                body_hash: (1000 + i) as u64,
                dependencies: vec![dep.clone()],
                origin: None,
            };
            let unit_curr = AnalysisUnitMetadata {
                body_hash: if i % 37 == 0 {
                    (2000 + i) as u64
                } else {
                    (1000 + i) as u64
                },
                ..unit_prev.clone()
            };
            previous.push(unit_prev);
            current.push(unit_curr);
        }

        current.push(AnalysisUnitMetadata {
            unit_key: "TypeExtra.run".to_string(),
            unit_kind: AnalysisUnitKind::Function,
            body_hash: 999_999,
            dependencies: vec!["run299".to_string()],
            origin: None,
        });
        let _ = previous.pop();

        let indexed = compute_invalidation_report(&previous, &current);
        let naive = compute_invalidation_report_naive(&previous, &current);
        assert_eq!(indexed.changed_units, naive.changed_units);
        assert_eq!(indexed.added_units, naive.added_units);
        assert_eq!(indexed.removed_units, naive.removed_units);
        assert_eq!(indexed.invalidated_units, naive.invalidated_units);
    }

    #[test]
    fn invalidation_report_handles_large_dependency_chains() {
        let n = 4000usize;
        let mut previous = Vec::with_capacity(n);
        let mut current = Vec::with_capacity(n);
        for i in 0..n {
            let key = format!("unit_{i}");
            let dep = if i == 0 {
                "root".to_string()
            } else {
                format!("unit_{}", i - 1)
            };
            previous.push(AnalysisUnitMetadata {
                unit_key: key.clone(),
                unit_kind: AnalysisUnitKind::Function,
                body_hash: i as u64,
                dependencies: vec![dep.clone()],
                origin: None,
            });
            current.push(AnalysisUnitMetadata {
                unit_key: key,
                unit_kind: AnalysisUnitKind::Function,
                body_hash: if i == 0 { 777 } else { i as u64 },
                dependencies: vec![dep],
                origin: None,
            });
        }

        let report = compute_invalidation_report(&previous, &current);
        assert_eq!(report.changed_units, vec!["unit_0".to_string()]);
        assert_eq!(report.invalidated_units.len(), n);
    }

    #[test]
    fn invalidation_report_marks_dependents_of_changed_impl_method() {
        let previous = parse(
            "impl Point {\n    fn new: () :i64 {\n        return 1\n    }\n}\nfn main: () :i64 {\n    return Point::new()\n}\n",
        )
        .expect("parse previous");
        let current = parse(
            "impl Point {\n    fn new: () :i64 {\n        return 2\n    }\n}\nfn main: () :i64 {\n    return Point::new()\n}\n",
        )
        .expect("parse current");

        let report = compute_invalidation_report(
            &analysis_units_for_program(&previous),
            &analysis_units_for_program(&current),
        );

        assert!(report.changed_units.contains(&"impl::Point".to_string()));
        assert!(report.changed_units.contains(&"Point.new".to_string()));
        assert!(report.invalidated_units.contains(&"main".to_string()));
    }

    #[test]
    fn invalidation_report_matches_member_access_to_type_field_units() {
        let previous = Program {
            statements: vec![
                Statement::Type {
                    name: "Point".to_string(),
                    parent: None,
                    fields: vec![Statement::Let {
                        name: "x".to_string(),
                        data_type: DataType::I64,
                        value: Some(Expression::Literal(Literal::Int(1))),
                        is_constant: false,
                        is_mutable: false,
                        is_static: false,
                        visibility: Visibility::Public,
                    }],
                },
                Statement::Function {
                    name: "main".to_string(),
                    params: vec![],
                    body: vec![Statement::Expression(Expression::MemberAccess {
                        target: Box::new(Expression::Identifier(Identifier {
                            name: "point".to_string(),
                            data_type: DataType::StructNamed("Point".to_string()),
                            line: 0,
                            column: 0,
                        })),
                        member: "x".to_string(),
                        data_type: DataType::Unknown,
                    })],
                    return_type: DataType::None,
                    visibility: Visibility::Public,
                    is_method: false,
                },
            ],
        };
        let mut current = previous.clone();
        let Statement::Type { fields, .. } = &mut current.statements[0] else {
            panic!("expected type");
        };
        let Statement::Let { value, .. } = &mut fields[0] else {
            panic!("expected field");
        };
        *value = Some(Expression::Literal(Literal::Int(2)));

        let report = compute_invalidation_report(
            &analysis_units_for_program(&previous),
            &analysis_units_for_program(&current),
        );

        assert!(report.changed_units.contains(&"Point#x".to_string()));
        assert!(report.invalidated_units.contains(&"main".to_string()));
    }
}
