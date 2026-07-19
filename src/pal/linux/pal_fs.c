#include "../pal.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <fcntl.h>
#include <pwd.h>

#define EXPAND_TILDE(var) char *var##_exp = expand_tilde(var); \
    const char *var##_real = var##_exp ? var##_exp : var
#define EXPAND_TILDE_END(var) free(var##_exp)

static char *expand_tilde(const char *path) {
    if (!path || path[0] != '~') return NULL;

    // ~ alone or ~/path
    if (path[1] == '\0' || path[1] == '/') {
        const char *home = getenv("HOME");
        if (!home) return NULL;
        size_t hlen = strlen(home);
        size_t plen = (path[1] == '\0') ? 0 : strlen(path) - 1;
        char *out = (char *)malloc(hlen + plen + 1);
        if (!out) return NULL;
        memcpy(out, home, hlen);
        if (plen > 0) memcpy(out + hlen, path + 1, plen + 1);
        else out[hlen] = '\0';
        return out;
    }

    // ~user/path or ~user
    const char *slash = strchr(path + 1, '/');
    size_t user_len = slash ? (size_t)(slash - path - 1) : strlen(path + 1);
    char user[256];
    if (user_len >= sizeof(user)) return NULL;
    memcpy(user, path + 1, user_len);
    user[user_len] = '\0';

    struct passwd *pw = getpwnam(user);
    if (!pw || !pw->pw_dir) return NULL;

    size_t dlen = strlen(pw->pw_dir);
    size_t rest_len = slash ? strlen(slash) : 0;
    char *out = (char *)malloc(dlen + rest_len + 1);
    if (!out) return NULL;
    memcpy(out, pw->pw_dir, dlen);
    if (rest_len > 0) memcpy(out + dlen, slash, rest_len + 1);
    else out[dlen] = '\0';
    return out;
}

int pal_fs_write(const char *path, const char *content) {
    EXPAND_TILDE(path);
    FILE *fh = fopen(path_real, "w");
    int ok = fh ? (fputs(content, fh) >= 0) : 0;
    if (fh) fclose(fh);
    EXPAND_TILDE_END(path);
    return ok ? 1 : 0;
}

int pal_fs_append(const char *path, const char *content) {
    EXPAND_TILDE(path);
    FILE *fh = fopen(path_real, "a");
    int ok = fh ? (fputs(content, fh) >= 0) : 0;
    if (fh) fclose(fh);
    EXPAND_TILDE_END(path);
    return ok ? 1 : 0;
}

char *pal_fs_read(const char *path) {
    extern char *rt_managed_from_slice(const char *src, size_t len);
    EXPAND_TILDE(path);
    FILE *fh = fopen(path_real, "rb");
    if (!fh) { EXPAND_TILDE_END(path); return NULL; }
    fseek(fh, 0, SEEK_END);
    long size = ftell(fh);
    fseek(fh, 0, SEEK_SET);
    char *buf = (char *)malloc((size_t)(size + 1));
    if (!buf) { fclose(fh); EXPAND_TILDE_END(path); return NULL; }
    size_t read = fread(buf, 1, (size_t)size, fh);
    buf[read] = '\0';
    fclose(fh);
    EXPAND_TILDE_END(path);
    char *result = rt_managed_from_slice(buf, read);
    free(buf);
    return result;
}

char *pal_fs_read_bytes(const char *path) {
    extern char *rt_managed_alloc(size_t len);
    extern char *rt_managed_from_slice(const char *src, size_t len);
    EXPAND_TILDE(path);
    FILE *fh = fopen(path_real, "rb");
    if (!fh) { EXPAND_TILDE_END(path); return rt_managed_from_slice("", 0); }
    fseek(fh, 0, SEEK_END);
    long size = ftell(fh);
    fseek(fh, 0, SEEK_SET);
    char *result = rt_managed_alloc((size_t)size);
    if (!result) { fclose(fh); EXPAND_TILDE_END(path); return rt_managed_from_slice("", 0); }
    if (size > 0) fread(result, 1, (size_t)size, fh);
    result[size] = '\0';
    fclose(fh);
    EXPAND_TILDE_END(path);
    return result;
}

int pal_fs_write_bytes(const char *path, const char *data, int64_t len) {
    EXPAND_TILDE(path);
    if (len < 0) len = 0;
    FILE *fh = fopen(path_real, "wb");
    if (!fh) { EXPAND_TILDE_END(path); return 0; }
    fwrite(data, 1, (size_t)len, fh);
    fclose(fh);
    EXPAND_TILDE_END(path);
    return 1;
}

int pal_fs_copy(const char *src, const char *dst) {
    EXPAND_TILDE(src);
    EXPAND_TILDE(dst);
    FILE *in = fopen(src_real, "rb");
    if (!in) { EXPAND_TILDE_END(dst); EXPAND_TILDE_END(src); return 0; }
    FILE *out = fopen(dst_real, "wb");
    if (!out) { fclose(in); EXPAND_TILDE_END(dst); EXPAND_TILDE_END(src); return 0; }
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0)
        fwrite(buf, 1, n, out);
    fclose(in);
    fclose(out);
    EXPAND_TILDE_END(dst);
    EXPAND_TILDE_END(src);
    return 1;
}

int pal_fs_move(const char *src, const char *dst) {
    EXPAND_TILDE(src);
    EXPAND_TILDE(dst);
    int r = rename(src_real, dst_real);
    if (r == 0) { EXPAND_TILDE_END(dst); EXPAND_TILDE_END(src); return 1; }
    FILE *in = fopen(src_real, "rb");
    if (!in) { EXPAND_TILDE_END(dst); EXPAND_TILDE_END(src); return 0; }
    FILE *out = fopen(dst_real, "wb");
    if (!out) { fclose(in); EXPAND_TILDE_END(dst); EXPAND_TILDE_END(src); return 0; }
    char buf[4096];
    size_t n;
    while ((n = fread(buf, 1, sizeof(buf), in)) > 0)
        fwrite(buf, 1, n, out);
    fclose(in);
    fclose(out);
    remove(src_real);
    EXPAND_TILDE_END(dst);
    EXPAND_TILDE_END(src);
    return 1;
}

int pal_fs_delete(const char *path) {
    EXPAND_TILDE(path);
    int result = remove(path_real) == 0 ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int pal_fs_mkdir(const char *path) {
    EXPAND_TILDE(path);
    int result = mkdir(path_real, 0755) == 0 ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int pal_fs_rmdir(const char *path) {
    EXPAND_TILDE(path);
    int result = rmdir(path_real) == 0 ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int64_t pal_fs_exists(const char *path) {
    EXPAND_TILDE(path);
    int64_t result = access(path_real, F_OK) == 0 ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int64_t pal_fs_is_dir(const char *path) {
    EXPAND_TILDE(path);
    struct stat st;
    int64_t result = (stat(path_real, &st) == 0 && S_ISDIR(st.st_mode)) ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int64_t pal_fs_is_file(const char *path) {
    EXPAND_TILDE(path);
    struct stat st;
    int64_t result = (stat(path_real, &st) == 0 && S_ISREG(st.st_mode)) ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}

int64_t pal_fs_size(const char *path) {
    EXPAND_TILDE(path);
    struct stat st;
    int64_t result = 0;
    if (stat(path_real, &st) == 0) result = (int64_t)st.st_size;
    EXPAND_TILDE_END(path);
    return result;
}

void *pal_fs_list(const char *path) {
    extern void *rt_list_create(int64_t initial_cap, int64_t elem_size);
    extern int64_t rt_list_len(void *list_ptr);
    extern void *rt_list_push_ptr(void *list_ptr, void *value);
    extern char *rt_strdup_raw(const char *src);
    EXPAND_TILDE(path);
    void *list = rt_list_create(16, 8);
    DIR *dir = opendir(path_real);
    if (!dir) { EXPAND_TILDE_END(path); return list; }
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.' && (entry->d_name[1] == '\0' || (entry->d_name[1] == '.' && entry->d_name[2] == '\0')))
            continue;
        char *name = rt_strdup_raw(entry->d_name);
        list = rt_list_push_ptr(list, name);
    }
    closedir(dir);
    EXPAND_TILDE_END(path);
    return list;
}

#define PAL_FS_WALK_MAX_DEPTH 32

static void walk_recursive(const char *path, void *result_list, int depth) {
    extern void *rt_list_push_ptr(void *list_ptr, void *value);
    extern char *rt_strdup_raw(const char *src);
    if (depth > PAL_FS_WALK_MAX_DEPTH) return;
    DIR *dir = opendir(path);
    if (!dir) return;
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.' && (entry->d_name[1] == '\0' || (entry->d_name[1] == '.' && entry->d_name[2] == '\0')))
            continue;
        char *full_path;
        if (asprintf(&full_path, "%s/%s", path, entry->d_name) == -1) continue;
        char *copied = rt_strdup_raw(full_path);
        void *pushed = rt_list_push_ptr(result_list, copied);
        if (pushed) result_list = pushed;
        struct stat st;
        if (lstat(full_path, &st) == 0 && S_ISDIR(st.st_mode)) {
            walk_recursive(full_path, result_list, depth + 1);
        }
        free(full_path);
    }
    closedir(dir);
}

void *pal_fs_walk(const char *path) {
    extern void *rt_list_create(int64_t initial_cap, int64_t elem_size);
    void *list = rt_list_create(64, 8);
    EXPAND_TILDE(path);
    walk_recursive(path_real, list, 0);
    EXPAND_TILDE_END(path);
    return list;
}

char *pal_fs_join(const char *a, const char *b) {
    extern char *rt_managed_from_cstr(const char *src);
    size_t alen = strlen(a);
    size_t blen = strlen(b);
    // Skip trailing '/' in a and leading '/' in b to avoid double slashes
    while (alen > 0 && a[alen - 1] == '/') alen--;
    while (blen > 0 && b[0] == '/') { b++; blen--; }
    char *tmp = (char *)malloc(alen + blen + 2);
    if (!tmp) return NULL;
    memcpy(tmp, a, alen);
    tmp[alen] = '/';
    memcpy(tmp + alen + 1, b, blen);
    tmp[alen + blen + 1] = '\0';
    char *result = rt_managed_from_cstr(tmp);
    free(tmp);
    return result;
}

char *pal_fs_dir(const char *path) {
    extern char *rt_managed_from_slice(const char *src, size_t len);
    EXPAND_TILDE(path);
    const char *slash = strrchr(path_real, '/');
    if (!slash) { EXPAND_TILDE_END(path); return NULL; }
    size_t len = (size_t)(slash - path_real);
    char *result = rt_managed_from_slice(path_real, len);
    EXPAND_TILDE_END(path);
    return result;
}

char *pal_fs_name(const char *path) {
    extern char *rt_managed_from_cstr(const char *src);
    EXPAND_TILDE(path);
    const char *slash = strrchr(path_real, '/');
    const char *base = slash ? slash + 1 : path_real;
    char *result = rt_managed_from_cstr(base);
    EXPAND_TILDE_END(path);
    return result;
}

char *pal_fs_ext(const char *path) {
    extern char *rt_managed_from_cstr(const char *src);
    EXPAND_TILDE(path);
    const char *dot = strrchr(path_real, '.');
    if (!dot || dot == path_real) { EXPAND_TILDE_END(path); return NULL; }
    char *result = rt_managed_from_cstr(dot);
    EXPAND_TILDE_END(path);
    return result;
}

int pal_fs_write_secure(const char *path, const char *content, int mode) {
    EXPAND_TILDE(path);
    int fd = open(path_real, O_WRONLY | O_CREAT | O_TRUNC, (mode_t)mode);
    if (fd < 0) { EXPAND_TILDE_END(path); return 0; }
    FILE *fh = fdopen(fd, "w");
    if (!fh) { close(fd); EXPAND_TILDE_END(path); return 0; }
    int ok = (fputs(content, fh) >= 0) ? 1 : 0;
    fclose(fh);
    EXPAND_TILDE_END(path);
    return ok;
}

int pal_fs_chmod(const char *path, int mode) {
    EXPAND_TILDE(path);
    int result = chmod(path_real, (mode_t)mode) == 0 ? 1 : 0;
    EXPAND_TILDE_END(path);
    return result;
}
