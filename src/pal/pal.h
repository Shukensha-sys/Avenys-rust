#ifndef MIRE_PAL_H
#define MIRE_PAL_H

#include <stddef.h>
#include <stdint.h>

// PAL — Platform Abstraction Layer
// Each domain groups system calls behind a stable API.
// Platform backends live in pal/<platform>/ directories.
//
// OWNERSHIP CONVENTION (C → Mire boundary):
// All functions returning char* MUST use rt_managed_* allocation
// (rt_managed_from_cstr, rt_managed_from_slice, rt_managed_alloc).
// The Mire GC tracks managed pointers; raw malloc/strdup leaks.
// Rationale: avenys FFI does not support struct-by-value returns,
// so PalBuf-as-struct is not feasible. Convention + enforcement
// via this header is the pragmatic path.
//
// CONCURRENCY INVARIANTS:
//   1. No function may have unprotected global mutable state.
//   2. All state is returned by value or via output parameters.
//   3. Per-thread state uses _Thread_local at minimum.
//   4. New functions MUST NOT introduce global state; prefer
//      return-by-value or caller-provided buffers.
//   5. Existing globals: pal_last_signal (volatile, read-only after init),
//      pal_last_stderr (_Thread_local). Both follow the invariant.
//
// RESULT CONVENTION (result[T E] pattern — i64 packed):
//   Since avenys FFI does not support struct-by-value, result types
//   are encoded as i64: high 32 bits = error code (0 = ok),
//   low bit = success flag. New functions may adopt this pattern.
//   Example: int64_t pal_fs_write_status(path, content, mode)
//     returns PAL_OK(0) on success, PAL_ERRNO(errno) on failure.
//   PAL_OK(v)       = ((int64_t)(v) << 32) | 1
//   PAL_ERR(e)      = ((int64_t)(e) << 32) | 0
//   PAL_STATUS_OK(s) = ((s) & 1) != 0
//   PAL_STATUS_ERR(s) = (int32_t)((s) >> 32)

#define PAL_OK(v)          (((int64_t)(v) << 32) | 1)
#define PAL_ERR(e)         (((int64_t)(e) << 32) | 0)
#define PAL_STATUS_OK(s)   (((s) & 1) != 0)
#define PAL_STATUS_ERR(s)  ((int32_t)((s) >> 32))

// ── Build-time feature detection ─────────────────────────────────────
// Platform backends define PAL_HAS_* to 1 if the feature is available.
// Mire/kioto code can #if PAL_HAS_OPENSSL to guard TLS usage.

#ifndef PAL_HAS_OPENSSL
  #ifdef __linux__
    #define PAL_HAS_OPENSSL 1
  #else
    #define PAL_HAS_OPENSSL 0
  #endif
#endif

#ifndef PAL_HAS_GETADDRINFO
  #ifdef __linux__
    #define PAL_HAS_GETADDRINFO 1
  #else
    #define PAL_HAS_GETADDRINFO 0
  #endif
#endif

#ifndef PAL_HAS_PTHREAD
  #ifdef __linux__
    #define PAL_HAS_PTHREAD 1
  #else
    #define PAL_HAS_PTHREAD 0
  #endif
#endif

#ifndef PAL_HAS_SIGNAL
  #ifdef __linux__
    #define PAL_HAS_SIGNAL 1
  #else
    #define PAL_HAS_SIGNAL 0
  #endif
#endif

#ifndef PAL_HAS_CHMOD
  #ifdef __linux__
    #define PAL_HAS_CHMOD 1
  #else
    #define PAL_HAS_CHMOD 0
  #endif
#endif

#ifndef PAL_HAS_LSTAT
  #ifdef __linux__
    #define PAL_HAS_LSTAT 1
  #else
    #define PAL_HAS_LSTAT 0
  #endif
#endif

// ── Filesystem ───────────────────────────────────────────────────────
int     pal_fs_write(const char *path, const char *content);
int     pal_fs_append(const char *path, const char *content);
char   *pal_fs_read(const char *path);
char   *pal_fs_read_bytes(const char *path);
int     pal_fs_write_bytes(const char *path, const char *data, int64_t len);
int     pal_fs_copy(const char *src, const char *dst);
int     pal_fs_move(const char *src, const char *dst);
int     pal_fs_delete(const char *path);
int     pal_fs_mkdir(const char *path);
int     pal_fs_rmdir(const char *path);
int64_t pal_fs_exists(const char *path);
int64_t pal_fs_is_dir(const char *path);
int64_t pal_fs_is_file(const char *path);
int64_t pal_fs_size(const char *path);
void   *pal_fs_list(const char *path);
void   *pal_fs_walk(const char *path);
char   *pal_fs_join(const char *a, const char *b);
char   *pal_fs_dir(const char *path);
char   *pal_fs_name(const char *path);
char   *pal_fs_ext(const char *path);
int     pal_fs_write_secure(const char *path, const char *content, int mode);
int     pal_fs_chmod(const char *path, int mode);

// ── Environment ──────────────────────────────────────────────────────
char   *pal_env_get(const char *name);
int     pal_env_set(const char *name, const char *value);
void   *pal_env_all(void);
char   *pal_env_cwd(void);
int     pal_env_chdir(const char *path);

// ── Process ──────────────────────────────────────────────────────────
char   *pal_proc_run(const char *cmd);
char   *pal_proc_exec(const char *cmd);
char   *pal_proc_shell(const char *cmd);
int64_t pal_proc_spawn(const char *cmd);
int64_t pal_proc_spawn_argv(const char **argv);  // execvp, no shell (safe)
int64_t pal_proc_wait(int64_t pid);  // returns -(128+sig) if killed by signal
int     pal_proc_kill(int64_t pid);
void    pal_proc_exit(int64_t status);
int64_t pal_proc_exists(int64_t pid);
char   *pal_proc_err(void);
void    pal_proc_on(const char *signal_name);
int     pal_proc_last_signal(void);

// ── Time ─────────────────────────────────────────────────────────────
int64_t pal_time_unix_ms(void);
int64_t pal_time_unix_ns(void);
int64_t pal_time_since_ms(int64_t start_ns);
int64_t pal_time_since_ns(int64_t start_ns);
void    pal_time_sleep_ms(int64_t ms);
void    pal_time_sleep_ns(int64_t ns);
int64_t pal_time_mark(void);
int64_t pal_time_elapsed_ms(int64_t start_ns);
int64_t pal_time_elapsed_ns(int64_t start_ns);

// ── CPU ──────────────────────────────────────────────────────────────
int64_t pal_cpu_time_ns(void);
int64_t pal_cpu_time_ms(void);
int64_t pal_cpu_mark(void);
int64_t pal_cpu_elapsed_ms(int64_t start_ns);
int64_t pal_cpu_elapsed_ns(int64_t start_ns);
int64_t pal_cpu_count(void);
int64_t pal_cpu_freq_mhz(void);
int64_t pal_cpu_cycles_est(int64_t start_ns);
void   *pal_cpu_loadavg(void);
void   *pal_cpu_snapshot(void);

// ── Memory ───────────────────────────────────────────────────────────
int64_t pal_mem_used(void);
int64_t pal_mem_total(void);
int64_t pal_mem_free(void);
int64_t pal_mem_available(void);
int64_t pal_mem_percent(void);
int64_t pal_mem_process_bytes(void);
void   *pal_mem_snapshot(void);
char   *pal_mem_format(int64_t bytes);

// ── GPU ──────────────────────────────────────────────────────────────
char   *pal_gpu_snapshot(void);

// ── Terminal ─────────────────────────────────────────────────────────
char   *pal_term_style(const char *text, const char *style);
char   *pal_term_hr(const char *ch, int64_t len);
char   *pal_term_clear(void);

// ── WebSocket ────────────────────────────────────────────────────────
int64_t pal_ws_connect(const char *host, int64_t port, const char *path);
int     pal_ws_send_text(int64_t fd, const char *data);
char   *pal_ws_recv(int64_t fd, int64_t max_bytes);
int     pal_ws_close(int64_t fd);
int64_t pal_wss_connect(const char *host, int64_t port, const char *path);
int     pal_wss_send_text(int64_t fd, const char *data);
char   *pal_wss_recv(int64_t fd, int64_t max_bytes);
int     pal_wss_close(int64_t fd);

// ── Networking ───────────────────────────────────────────────────────
int64_t pal_net_connect(const char *host, int64_t port);
int64_t pal_net_connect_timeout(const char *host, int64_t port, int64_t timeout_ms);
char   *pal_net_recv(int64_t fd, int64_t max_bytes);
int     pal_net_send(int64_t fd, const char *data);
int     pal_net_send_bytes(int64_t fd, const char *data, int64_t len);
int     pal_net_close(int64_t fd);
int64_t pal_net_poll(int64_t fd, int64_t timeout_ms);
int     pal_net_set_nonblock(int64_t fd, int nonblock);
char   *pal_net_resolve(const char *host);
int64_t pal_net_bind(int64_t port);          // dual-stack IPv4+IPv6
int64_t pal_net_accept(int64_t server_fd);   // works for both IPv4/IPv6

// ── TLS / SSL (OpenSSL) ──────────────────────────────────────────────
int64_t pal_tls_connect(const char *host, int64_t port);
int     pal_tls_send(int64_t fd, const char *data);
char   *pal_tls_recv(int64_t fd, int64_t max_bytes);
int     pal_tls_close(int64_t fd);

// ── Threads ──────────────────────────────────────────────────────────
int64_t pal_thread_spawn(void *(*fn)(void*), void *arg);
int64_t pal_thread_join(int64_t tid, void **result);
void    pal_thread_detach(int64_t tid);
void    pal_thread_exit(void *result);
int64_t pal_thread_self(void);

// ── I/O helpers ──────────────────────────────────────────────────────
void    pal_io_print(const char *msg);
void    pal_io_print_err(const char *msg);
char   *pal_io_readln(void);

#endif // MIRE_PAL_H
