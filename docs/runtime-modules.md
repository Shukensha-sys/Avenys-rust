# Mire Runtime Modules

This document describes the standard runtime modules currently exposed by Mire.

## Goals

- Keep the core runtime small and loaded on demand.
- Separate utilities by responsibility.
- Expose profiling and diagnostics as explicit modules instead of hidden globals.

## Core Built-ins

These stay in the language core:

- `dasu(...)`
- `ireru(...)`
- `type value`
- `range(...)`

`dasu` and `ireru` are the standard Mire I/O surface. Literal text must be quoted, and `{...}` interpolation is only recognized inside quoted strings.

`import std` imports the default standard surface. For explicit module-oriented code, prefer `import <module> as <alias>`.

## `time`

Import:

```mire
import time as time
```

Available members:

- `time.unix_ms()`
- `time.unix_ns()`
- `time.since_ms(start_unix_ms)`
- `time.since_ns(start_unix_ns)`
- `time.mark()`
- `time.elapsed_ms(mark_id)`
- `time.elapsed_ns(mark_id)`
- `time.sleep_ms(ms)`
- `time.sleep_ns(ns)`

Example:

```mire
import time as time

set mark = time.mark() :i64
set n = 0 :i64

while n < 100000 {
    set n += 1
}

use dasu("loop took {time.elapsed_ms(mark)} ms")
```

Notes:

- `unix_*` uses wall-clock time.
- `mark/elapsed_*` uses a monotonic timer and is the preferred way to benchmark Mire code.

## `mem`

Import:

```mire
import mem as mem
```

Available members:

- `mem.used()`
- `mem.total()`
- `mem.free()`
- `mem.available()`
- `mem.percent()`
- `mem.process()`
- `mem.snapshot()`
- `mem.format(bytes)`

Example:

```mire
import mem as mem

use dasu("total {mem.format(mem.total())}")
use dasu("used {mem.format(mem.used())}")
use dasu("process {mem.format(mem.process())}")
```

Notes:

- Values are returned in bytes unless explicitly formatted.
- `mem.process()` reports the current Mire process memory when the platform exposes it.
- `mem.snapshot()` returns a map with `used`, `total`, `free`, `available`, `process`, `percent`, and `unit`.

## `cpu`

Import:

```mire
import cpu as cpu
```

Available members:

- `cpu.time_ns()`
- `cpu.time_ms()`
- `cpu.mark()`
- `cpu.elapsed_ns(mark_id)`
- `cpu.elapsed_ms(mark_id)`
- `cpu.count()`
- `cpu.freq_mhz()`
- `cpu.cycles_est(mark_id)`
- `cpu.loadavg()`
- `cpu.snapshot()`

Notes:

- `cpu.time_*` measures process CPU time, not wall-clock time.
- `cpu.cycles_est(...)` is an estimate derived from CPU time and current CPU frequency.
- `cpu.loadavg()` returns system load averages when the platform exposes them.

## `gpu`

Import:

```mire
import gpu as gpu
```

Available members:

- `gpu.available()`
- `gpu.snapshot()`

Notes:

- The current implementation probes `nvidia-smi` on demand.
- If no supported GPU tooling is available, `gpu.snapshot()` returns `available=false`.

## `fs`

Import:

```mire
import fs as fs
```

Members:

- `fs.read(path)`
- `fs.write(path data)`
- `fs.append(path data)`
- `fs.exists(path)`
- `fs.size(path)`
- `fs.copy(src dst)`
- `fs.move(src dst)`
- `fs.drop(path)`
- `fs.list(path)`
- `fs.mkdir(path)`
- `fs.rmdir(path)`
- `fs.join(a b ...)`
- `fs.dir(path)`
- `fs.name(path)`
- `fs.ext(path)`

## `env`

Import:

```mire
import env as env
```

Members:

- `env.get(key)`
- `env.set(key value)`
- `env.all()`
- `env.args()`
- `env.cwd()`
- `env.chdir(path)`

## `proc`

Import:

```mire
import proc as proc
```

Members:

- `proc.run(cmd args)`
- `proc.spawn(cmd args)`
- `proc.pipe(commands)`
- `proc.shell(cmd)`
- `proc.read()`
- `proc.write(data)`
- `proc.write(proc.err data)`
- `proc.on(signal handler)`
- `proc.exit(code)`
- `proc.kill(handle_or_pid)`
- `proc.wait(handle_or_pid)`
- `proc.exists(handle_or_pid)`
