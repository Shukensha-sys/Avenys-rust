// Linux PAL — Networking
// POSIX sockets + poll + DNS resolution.
// DNS uses getaddrinfo (thread-safe, IPv4+IPv6 dual-stack).

#include "../pal.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <poll.h>
#include <errno.h>
#include <signal.h>

static int sigpipe_ignored = 0;

int64_t pal_net_connect(const char *host, int64_t port) {
    return pal_net_connect_timeout(host, port, 30000);
}

int64_t pal_net_connect_timeout(const char *host, int64_t port, int64_t timeout_ms) {
    // Resolve hostname — thread-safe, IPv4+IPv6
    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;
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

        if (timeout_ms > 0) {
            int flags = fcntl(fd, F_GETFL, 0);
            if (flags >= 0) fcntl(fd, F_SETFL, flags | O_NONBLOCK);
        }

        int ret = connect(fd, rp->ai_addr, rp->ai_addrlen);
        if (ret < 0 && errno == EINPROGRESS) {
            struct pollfd pfd;
            pfd.fd = fd;
            pfd.events = POLLOUT;
            int pr = poll(&pfd, 1, (int)timeout_ms);
            if (pr <= 0) {
                close(fd);
                fd = -1;
                continue;
            }
            int err = 0;
            socklen_t len = sizeof(err);
            if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &err, &len) < 0 || err != 0) {
                close(fd);
                fd = -1;
                continue;
            }
        } else if (ret < 0) {
            close(fd);
            fd = -1;
            continue;
        }

        // Connected — restore blocking mode
        if (timeout_ms > 0) {
            int flags = fcntl(fd, F_GETFL, 0);
            if (flags >= 0) fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);
        }
        break;  // success
    }
    freeaddrinfo(res);

    return (fd >= 0) ? (int64_t)fd : -1;
}

char *pal_net_recv(int64_t fd, int64_t max_bytes) {
    extern char *rt_managed_from_slice(const char *src, size_t len);
    if (max_bytes <= 0) max_bytes = 65536;
    char *buf = (char *)malloc((size_t)max_bytes + 1);
    if (!buf) return NULL;
    ssize_t n = read((int)fd, buf, (size_t)max_bytes);
    if (n <= 0) {
        free(buf);
        return NULL;
    }
    buf[n] = '\0';
    char *result = rt_managed_from_slice(buf, (size_t)n);
    free(buf);
    return result;
}

int pal_net_send(int64_t fd, const char *data) {
    if (!data) return 0;
    size_t len = strlen(data);
    ssize_t written = write((int)fd, data, len);
    return (written == (ssize_t)len) ? 1 : 0;
}

int pal_net_send_bytes(int64_t fd, const char *data, int64_t len) {
    if (!data || len <= 0) return 0;
    ssize_t written = write((int)fd, data, (size_t)len);
    return (written == (ssize_t)len) ? 1 : 0;
}

int pal_net_close(int64_t fd) {
    return close((int)fd) == 0 ? 1 : 0;
}

int64_t pal_net_poll(int64_t fd, int64_t timeout_ms) {
    struct pollfd pfd;
    pfd.fd = (int)fd;
    pfd.events = POLLIN;
    int ret = poll(&pfd, 1, (int)timeout_ms);
    return (int64_t)ret;
}

int pal_net_set_nonblock(int64_t fd, int nonblock) {
    int flags = fcntl((int)fd, F_GETFL, 0);
    if (flags < 0) return 0;
    if (nonblock)
        flags |= O_NONBLOCK;
    else
        flags &= ~O_NONBLOCK;
    return fcntl((int)fd, F_SETFL, flags) == 0 ? 1 : 0;
}

// Bind a server socket — dual-stack (IPv4+IPv6) when available.
int64_t pal_net_bind(int64_t port) {
    if (!sigpipe_ignored) {
        signal(SIGPIPE, SIG_IGN);
        sigpipe_ignored = 1;
    }

    // Try IPv6 first (dual-stack with IPV6_V6ONLY=0)
    int fd = socket(AF_INET6, SOCK_STREAM, 0);
    if (fd >= 0) {
        int off = 0;
        setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &off, sizeof(off));
        int opt = 1;
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        struct sockaddr_in6 addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin6_family = AF_INET6;
        addr.sin6_addr   = in6addr_any;
        addr.sin6_port   = htons((uint16_t)port);

        if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) == 0 &&
            listen(fd, SOMAXCONN) == 0) {
            return (int64_t)fd;
        }
        close(fd);
    }

    // Fallback to IPv4
    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons((uint16_t)port);

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    if (listen(fd, SOMAXCONN) < 0) {
        close(fd);
        return -1;
    }
    return (int64_t)fd;
}

// Accept a connection — works for both IPv4 and IPv6 server sockets.
int64_t pal_net_accept(int64_t server_fd) {
    struct sockaddr_storage client_addr;
    socklen_t len = sizeof(client_addr);
    int client_fd = accept((int)server_fd, (struct sockaddr *)&client_addr, &len);
    return (int64_t)client_fd;
}

// DNS resolution — thread-safe, returns first resolved address as string.
char *pal_net_resolve(const char *host) {
    extern char *rt_managed_from_cstr(const char *src);
    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    int gai = getaddrinfo(host, NULL, &hints, &res);
    if (gai != 0 || !res) {
        if (res) freeaddrinfo(res);
        return NULL;
    }

    char addr_buf[INET6_ADDRSTRLEN];
    addr_buf[0] = '\0';

    if (res->ai_family == AF_INET) {
        struct sockaddr_in *sa = (struct sockaddr_in *)res->ai_addr;
        inet_ntop(AF_INET, &sa->sin_addr, addr_buf, sizeof(addr_buf));
    } else if (res->ai_family == AF_INET6) {
        struct sockaddr_in6 *sa = (struct sockaddr_in6 *)res->ai_addr;
        inet_ntop(AF_INET6, &sa->sin6_addr, addr_buf, sizeof(addr_buf));
    }

    freeaddrinfo(res);

    if (addr_buf[0] == '\0') return NULL;
    return rt_managed_from_cstr(addr_buf);
}
