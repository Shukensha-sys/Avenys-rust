// Linux PAL — TLS via OpenSSL
// Links with -lssl -lcrypto
//
// Security: SSL_VERIFY_PEER is ON by default. Hostname verification and
// SNI are enabled. DNS resolution uses getaddrinfo (thread-safe, IPv4+IPv6).
// The PalTlsConn struct bundles ctx+ssl+fd so both SSL_CTX and SSL are freed
// on close — no resource leaks.

#include "../pal.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

// ── Internal: bundled TLS connection handle ──────────────────────────
typedef struct {
    SSL_CTX *ctx;
    SSL     *ssl;
    int      sock_fd;
} PalTlsConn;

static int ssl_initialized = 0;

static void init_ssl(void) {
    if (!ssl_initialized) {
        SSL_load_error_strings();
        OpenSSL_add_ssl_algorithms();
        ssl_initialized = 1;
    }
}

// Create a context with peer verification ON and system CA store.
static SSL_CTX *create_ssl_context(void) {
    const SSL_METHOD *method = TLS_client_method();
    SSL_CTX *ctx = SSL_CTX_new(method);
    if (!ctx) return NULL;
    SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, NULL);
    SSL_CTX_set_default_verify_paths(ctx);
    return ctx;
}

// ── Public API ──────────────────────────────────────────────────────

int64_t pal_tls_connect(const char *host, int64_t port) {
    init_ssl();

    // Resolve hostname — getaddrinfo is thread-safe, IPv4+IPv6
    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;    // IPv4 or IPv6
    hints.ai_socktype = SOCK_STREAM;

    char port_str[16];
    snprintf(port_str, sizeof(port_str), "%lld", (long long)port);

    int gai = getaddrinfo(host, port_str, &hints, &res);
    if (gai != 0 || !res) {
        if (res) freeaddrinfo(res);
        return -1;
    }

    // Try each resolved address until one connects
    int fd = -1;
    struct addrinfo *rp;
    for (rp = res; rp != NULL; rp = rp->ai_next) {
        fd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
        if (fd < 0) continue;
        if (connect(fd, rp->ai_addr, rp->ai_addrlen) == 0) break;
        close(fd);
        fd = -1;
    }
    freeaddrinfo(res);

    if (fd < 0) return -1;

    // Create TLS context
    SSL_CTX *ctx = create_ssl_context();
    if (!ctx) {
        close(fd);
        return -1;
    }

    SSL *ssl = SSL_new(ctx);
    if (!ssl) {
        SSL_CTX_free(ctx);
        close(fd);
        return -1;
    }

    SSL_set_fd(ssl, fd);

    // Hostname verification (OpenSSL ≥1.1.0)
    SSL_set1_host(ssl, host);

    // SNI — Server Name Indication (required for virtual hosting)
    SSL_set_tlsext_host_name(ssl, host);

    // Perform TLS handshake
    if (SSL_connect(ssl) != 1) {
        SSL_free(ssl);
        SSL_CTX_free(ctx);
        close(fd);
        return -1;
    }

    // Bundle ctx+ssl+fd so close can free everything
    PalTlsConn *conn = (PalTlsConn *)malloc(sizeof(PalTlsConn));
    if (!conn) {
        SSL_free(ssl);
        SSL_CTX_free(ctx);
        close(fd);
        return -1;
    }
    conn->ctx     = ctx;
    conn->ssl     = ssl;
    conn->sock_fd = fd;

    return (int64_t)(intptr_t)conn;
}

int pal_tls_send(int64_t handle, const char *data) {
    if (!data) return 0;
    PalTlsConn *conn = (PalTlsConn *)(intptr_t)handle;
    if (!conn || !conn->ssl) return 0;
    size_t len = strlen(data);
    int written = SSL_write(conn->ssl, data, (int)len);
    return written == (int)len ? 1 : 0;
}

char *pal_tls_recv(int64_t handle, int64_t max_bytes) {
    extern char *rt_managed_from_slice(const char *src, size_t len);
    if (max_bytes <= 0) max_bytes = 65536;
    PalTlsConn *conn = (PalTlsConn *)(intptr_t)handle;
    if (!conn || !conn->ssl) return NULL;
    char *buf = (char *)malloc((size_t)max_bytes + 1);
    if (!buf) return NULL;
    int n = SSL_read(conn->ssl, buf, (int)max_bytes);
    if (n <= 0) {
        free(buf);
        return NULL;
    }
    buf[n] = '\0';
    char *result = rt_managed_from_slice(buf, (size_t)n);
    free(buf);
    return result;
}

int pal_tls_close(int64_t handle) {
    PalTlsConn *conn = (PalTlsConn *)(intptr_t)handle;
    if (!conn) return 0;

    if (conn->ssl) {
        SSL_shutdown(conn->ssl);
        SSL_free(conn->ssl);
    }
    if (conn->ctx) {
        SSL_CTX_free(conn->ctx);
    }
    if (conn->sock_fd >= 0) {
        close(conn->sock_fd);
    }
    free(conn);
    return 1;
}
