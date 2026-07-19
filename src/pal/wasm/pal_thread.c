// WASM PAL — Thread stubs
// WASM has no POSIX threads (pthread), so thread operations are unsupported.

#include "pal.h"

int64_t pal_thread_spawn(void *(*fn)(void*), void *arg) {
    (void)fn; (void)arg;
    return -1;
}

int64_t pal_thread_join(int64_t tid, void **result) {
    (void)tid;
    if (result) *result = NULL;
    return -1;
}

void pal_thread_detach(int64_t tid) {
    (void)tid;
}

void pal_thread_exit(void *result) {
    (void)result;
}

int64_t pal_thread_self(void) {
    return 0;
}
