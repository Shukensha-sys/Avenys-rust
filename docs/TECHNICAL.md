# Documentación Técnica - Mire Compiler

Este documento complementa `docs/issues.md` con información de arquitectura para facilitar el desarrollo futuro.

---

## 1. Sistema de Cache Incremental

### Estructura de Archivos

```
bin/.cache/
└── incremental.bin  (crece sin límite - D2)
```

### Componentes del Cache

| Estructura | Descripción | Persistencia |
|------------|-------------|---------------|
| `files` | HashMap<Path, FileCacheEntry> | ✅ |
| `analyses` | HashMap<Key, AnalysisCacheEntry> | ✅ |
| `builds` | HashMap<Key, BuildCacheEntry> (agregado en D1) | ✅ |
| `blob_store` | Vec<u8> con datos serializados | ✅ |

### Formato del Archivo

```
[MAGIC: 8 bytes] "MIREINC2"
[VERSION: 4 bytes] u32
[FILES_COUNT: 8 bytes]
  - for each file:
    [KEY: string]
    [HASH: 8 bytes]
    [LAST_ACCESS: 8 bytes]
    [EXPORTS: string array]
    [IMPORTS: serialized]
    [BLOB_OFFSET: 8 bytes]
    [BLOB_LEN: 8 bytes]
[ANALYSES_COUNT: 8 bytes]
  - for each analysis:
    [KEY: string]
    [FINGERPRINT: 8 bytes]
    [LAST_ACCESS: 8 bytes]
    [CREATED: 8 bytes]  (agregado en B1)
    [BLOB_OFFSET: 8 bytes]
    [BLOB_LEN: 8 bytes]
    [UNIT_COUNT: 4 bytes]
[BLOBS: raw bytes...]
```

### Blob Store

El blob store es un append-only storage para datos serializados de análisis.

**Problema D2**: 
- Cada análisis se serializa y se appende al blob store
- Los offsets se almacenan en `AnalysisCacheEntry`
- Cuando `prune_lru` elimina análisis, los datos quedan huérfanos en el blob
- Nunca se compactan, el archivo crece indefinidamente

### Código Clave

```rust
// src/incremental.rs

// Líneas clave:
305-313:_blobStore enum definición
346-349: fn append()
520-522: load() - carga cache
524-548: save() - guarda cache (aquí se añadiría compactación)
795-840: fn prune_lru() -limpieza de entradas(D1)
1171-1176: fn append_blob()
```

---

## 2. Sistema de Tipos y Compilación

### Tipo `strings.split`

Antes (C2): Retornaba `str` (string concatenada con espacios)
Ahora: Retorna `List` (lista de strings)

```rust
// typeck.rs:351 - Antes: DataType::Str
// typeck.rs:351 - Ahora: DataType::List
```

## 3. Runtime C

### Funciones de String

| Función | Ubicación | Estado |
|---------|-----------|--------|
| `mire_string_to_upper` | runtime_support.c:830 | D3: Solo ASCII |
| `mire_string_to_lower` | runtime_support.c:846 | D3: Solo ASCII |
| `mire_strings_split` | runtime_support.c:1259 | Legacy (string) |
| `mire_strings_split_list` | runtime_support.c:1196 | C2: Nueva (lista) |
| `mire_dict_format_value` | runtime_support.c:917 | D4: Memory leak |

### Memory Leak D4

```c
// runtime_support.c:932-933
if (kind == MIRE_KIND_MAP) {
    return mire_strdup_raw(mire_dict_to_string(...));
    //                            ^
    // El resultado de mire_dict_to_string usa mire_managed_alloc
    // luego strdup hace otro malloc copy
    // El primer malloc NUNCA SE LIBERA
}
```

---

## 4. Borrow Checker

### Scope Handling

El borrow checker usa dos sistemas de scopes:

1. **Semantic Model** - Scope IDs globally unique
   - Asignados secuencialmente en `semantic.rs`
   - Usados para追踪 lifetime de borrow

2. **Borrow Checker** - Scope depth local
   - Calculado desde `scopes.len()`
   - Usado para filtrar bindings por scope

### Posible Problema (B3)

Los scope IDs en el modelo semántico pueden no alinearse con los scope depths en el checker. Esto podría causar falsos negativos en `ensure_return_is_safe`.

---

## 5. Próximos Pasos

### Issues Prioritarios

| ID | Descripción | Dificultad | Estado |
|----|-------------|-------------|--------|
| D2 | Blob store compactation | Alta | ✅ Completado ( Mayo 2026) |
| D3 | to_upper/to_lower Unicode | Baja | ✅ Completado (Mayo 2026) |
| D4 | Memory leak dict format | Baja | ✅ Completado (Mayo 2026) |
| D5 | &mut decision | Baja | ✅ Completado (Mayo 2026) |

### Tests a Agregar

```rust
// tests/language_regressions.rs

#[test]
fn blob_store_compaction_removes_orphaned_data() {
    // 1. Crear cache con muchos análisis
    // 2. Invalidar la mitad
    // 3. Guardar y recargar
    // 4. Verificar tamaño de blob reducido
}

#[test]
fn string_to_upper_unicode() {
    // Probar con acentos
    set result = strings.to_upper("ñoño")
    assert_eq!(result, "ÑOÑO")
}
```

---

## 6. Checklist para D2 (Blob Store)

- [ ] Añadir campo `format_version` al CacheDb serialization
- [ ] Crear función `compact_blob_store(db, blob) -> new_blob + offset_mapping`
- [ ] En `save()`, detectar si compactación necesaria:
  - Calcular ratio: used_offsets / total_blob_size
  - Si < 0.7 Y tamaño > 1MB, compactar
- [ ] Actualizar todos los `blob_offset` después de compactar
- [ ] Test de compactación
- [ ] Test de backward compatibility (cache V3 → V4)

---

Última actualización: Mayo 2026