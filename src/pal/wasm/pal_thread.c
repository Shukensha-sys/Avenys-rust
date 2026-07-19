// WASM PAL — Thread stubs
// WASM has no POSIX threads (pthread), so thread operations are unsupported.

#include "pal.h"

int64_t pal_thread_join(int64_t tid, void **result) {
    (void)tid;
    if (result) {
        *result = NULL;
    }
    return -1;
}
