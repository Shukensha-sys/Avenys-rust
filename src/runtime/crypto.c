#include "runtime.h"
#include <stdint.h>

int64_t rt_crypto_byte_at(const char *s, int64_t i) {
    if (!s || i < 0) return 0;
    return (unsigned char)s[i];
}
