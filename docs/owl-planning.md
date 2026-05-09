# Owl - Gestor de Proyectos y Dependencias Mire

## Visión General

Owl es el gestor de proyectos, dependencias y compilación para el ecosistema Mire. Escrito en código Mire y compilado por Avenys, funciona como binario CLI independiente.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      Usuario                                │
└─────────────────────┬───────────────────────────────────────┘
                      │ owl <comando>
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                    Binario Owl (Mire)                       │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐│
│  │  new    │ │  run    │ │install  │ │ purge   │ │ compile││
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬───┘│
└───────┼────────────┼──────────┼───────────┼────────────┼────┘
        │            │          │           │            │
        │            │          ▼           │            ▼
        │            │   ┌─────────────┐     │    ┌──────────────┐
        │            │   │$HOME/.owl/  │     │    │   Avenys    │
        │            │   │  DepName/   │     │    │ (Compilador)│
        │            │   └─────────────┘     │    └──────────────┘
        │            │          │
        │            ▼          ▼
        │   ┌─────────────┐  ┌─────────────┐
        │   │ owl.toml    │  │ owl.lock    │
        │   └─────────────┘  └─────────────┘
        │
        ▼
   Git (control de versiones)
```

## Estructura de Proyecto

```
mi-proyecto/
├── owl.toml          # Configuración del proyecto
├── owl.lock          # Lock de dependencias (generado)
├── .git/             # Repositorio Git
├── code/
│   └── main.mire     # Entry point
├── tests/
│   └── smoke.mire
└── bin/
    ├── debug/
    └── release/
```

## owl.toml (Schema)

```toml
[owl]
version = "1.0.0"

[project]
name = "mi-proyecto"
version = "0.1.0"
entry = "code/main.mire"

[dependencies]
# name = "version" o "url:..." o "git:..."
# std = "1.0.0"           # oficial
# milib = "git:https://..." # git
# bar = "url:https://..."  # url directa

[build]
optimization = "release"
debug = false

[signatures]
# Para verificación futura de dependencias
# pubkey = "..."
```

## owl.lock (Schema)

```toml
[locked]
version = "1.0.0"

[[dependency]]
name = "milib"
version = "1.2.3"
source = "git:https://github.com/..."
commit = "abc123"
hash = "sha256:..."

[[dependency]]
name = "std"
version = "1.0.0"
source = "builtin"
```

## Comandos CLI

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `owl new <name>` | Crear proyecto nuevo + git init | `owl new mi-proyecto` |
| `owl run [path]` | Ejecutar proyecto/archivo | `owl run` / `owl run main` |
| `owl compile [path]` | Compilar proyecto/archivo | `owl compile` / `owl compile main` |
| `owl install <url>` | Instalar dependencia | `owl install git:https://...` |
| `owl purge <name>` | Eliminar dependencia | `owl purge milib` |
| `owl info` | Info del proyecto | Muestra config y deps |
| `owl clean` | Limpiar artefactos | Elimina bin/ y caches |
| `owl version` | Version de owl | Muestra versión |

### Flags Globales

| Flag | Descripción |
|------|-------------|
| `--debug` | Modo debug (bin/debug/, persiste .ll) |
| `--release` | Modo release (bin/release/, -O3) |
| `--entry <path>` | Sobrescribir entry point |

### Flags de Ejecución

| Flag | Descripción |
|------|-------------|
| `--ms` | Mostrar tiempo wall-clock |
| `--memory`, `-m` | Mostrar pico de memoria |
| `--cpu` | Mostrar tiempo de CPU |

### Flags de Proyecto

| Flag | Descripción |
|------|-------------|
| `--template <name>` | Template de proyecto (basic, lib) |

## Gestión de Dependencias

### Estructura de Instalación

```
$HOME/.owl/
├── std/
│   ├── version.toml
│   ├── code/
│   │   └── std.mire
│   └── owl.lock
├── milib/
│   ├── version.toml
│   ├── code/
│   │   └── milib.mire
│   └── owl.lock
└── cache/
    └── ...
```

### Flujo de owl install

1. Parsear owl.toml
2. Para cada dependencia:
   - Si URL: descargar a `$HOME/.owl/Nombre/`
   - Si Git: clonar repositorio
   - Verificar versión con Semver
   - (Futuro) Verificar firma
3. Generar owl.lock con hashes
4. Guardar locks

### Flujo de owl purge

1. Parsear owl.toml
2. Eliminar directorio de `$HOME/.owl/Nombre/`
3. Regenerar owl.lock sin la dependencia
4. Actualizar owl.toml

## Seguridad

### Semver

- Parser de versiones en Mire
- Soporte para: `1.0.0`, `^1.0.0`, `~1.0.0`, `>=1.0.0`

### Firmas (Futuro)

- Verificación de firmas de dependencias
- Claves públicas configuradas en owl.toml

### Hashes

- SHA-256 en owl.lock
- Validación de integridad de dependencias

### Conflictos

- Validar que dependencia no rompa código principal
- Verificar compatibilidad de versiones

## Git Integrado

`owl new` → crea proyecto + `git init` + primer commit opcional

```
owl new mi-proyecto
→ Crea estructura
→ git init
→ git add .
→ Initial commit (opcional)
```

## Integración con Avenys

Owl orquestra Avenys:

| Operación | Acción |
|-----------|--------|
| Compilar proyecto | Llama a Avenys (mire build) |
| Ejecutar | Llama a Avenys (mire run) |
| Info | Lee configuración de Avenys |

Owl NO reimplementa la compilación - solo orquestra.

## Instalación

### curl | bash

```bash
curl -fssl https://install.owl-lang.org | bash
```

Script:
1. Detectar OS
2. Descargar binario pre-compilado (o compilar desde source)
3. Mover a `/usr/local/bin/owl` o `~/.local/bin/owl`
4. Configurar completions (bash/zsh)
5. Crear `~/.owl/` para dependencias
6. Verificar instalación con `owl version`

## Bootstrapping

Owl puede gestionar el bootstrapping de Avenys cuando el compilador se reescriba en Mire:

```
owl bootstrap
→ Descarga código fuente de Avenys (Mire)
→ Compila con versión actual de Avenys
→ Genera nuevo binario de Avenys
```

## Roadmap de Implementación

### Fase 1: Proyecto Owl en Mire
- [x] Estructura de proyecto en Mire
- [x] Parser de owl.toml
- [x] Compilación básica con Avenys

### Fase 2: CLI Básica
- [x] `owl new` - crear proyecto
- [x] `owl run` - ejecutar
- [x] `owl compile` - compilar
- [x] `owl clean` - limpiar
- [x] `owl info` - info del proyecto
- [x] `owl version` - versión

### Fase 3: Git Integrado
- [ ] `owl new` + `git init`
- [ ] Commit inicial automático

### Fase 4: Gestión de Dependencias
- [x] `owl install` - instalar dependencias (git: y url:)
- [x] `owl purge` - eliminar dependencias
- [x] `owl deps` - listar dependencias
- [x] Estructura $HOME/.owl/
- [ ] owl.lock generation

### Fase 5: Seguridad
- [ ] Parser Semver
- [ ] Hashes en owl.lock
- [ ] Verificación de firmas (futuro)

### Fase 6: Instalador
- [ ] Script curl | bash
- [ ] Binario pre-compilado

### Fase 7: Bootstrapping
- [ ] `owl bootstrap` para reescribir Avenys en Mire

## Notas de Diseño

1. **KISS**: Mantener simple y mínimo
2. **Sin aliasing**: Integración nativa, sin atajos
3. **Compatible**: Trabajo conjunto owl + Avenys
4. **Seguro**: Semver + firmas + hashes
5. **Bootstrappable**: Capaz de reescribirse a sí mismo

---

Última actualización: Mayo 2026