#include "runtime.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int64_t rt_crypto_byte_at(const char *s, int64_t i) {
    if (!s || i < 0) return 0;
    return (unsigned char)s[i];
}

char *rt_read_bytes(const char *path) {
    if (!path) return rt_managed_from_slice("", 0);
    FILE *fh = fopen(path, "rb");
    if (!fh) return rt_managed_from_slice("", 0);
    fseek(fh, 0, SEEK_END);
    long size = ftell(fh);
    fseek(fh, 0, SEEK_SET);
    if (size <= 0) { fclose(fh); return rt_managed_from_slice("", 0); }
    char *result = rt_managed_alloc((size_t)size);
    if (!result) { fclose(fh); return rt_managed_from_slice("", 0); }
    fread(result, 1, (size_t)size, fh);
    result[size] = '\0';
    fclose(fh);
    return result;
}
