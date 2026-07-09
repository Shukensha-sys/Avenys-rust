#include "runtime.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

static int hex_digit(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return 0;
}

int rt_hex_to_file(const char *path, const char *hex) {
    if (!path || !hex) return 0;
    FILE *fh = fopen(path, "wb");
    if (!fh) return 0;
    size_t len = strlen(hex);
    for (size_t i = 0; i + 1 < len; i += 2) {
        int hi = hex_digit((unsigned char)hex[i]);
        int lo = hex_digit((unsigned char)hex[i + 1]);
        unsigned char byte = (unsigned char)((hi << 4) | lo);
        fwrite(&byte, 1, 1, fh);
    }
    fclose(fh);
    return 1;
}
