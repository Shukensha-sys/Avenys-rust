#!/bin/sh
set -e

# ── Mire Toolchain Install ────────────────────────────────────────────
# Installs owl (Mire package manager) from the Avenys toolchain release.
#
# The release tarball includes: owl + kioto + Mire compiler + runtime.
# This script installs owl by default. The compiler is a secondary
# component available as a side-install option.
#
# Usage:
#   curl -fsSL <url> | sh                        # install owl (default)
#   curl -fsSL <url> | sh -s -- --yes            # non-interactive
#   curl -fsSL <url> | sh -s -- --prefix ~/.local # user install
#   curl -fsSL <url> | sh -s -- --no-profile     # skip PATH setup
#   curl -fsSL <url> | sh -s -- --compiler       # also install compiler
#   curl -fsSL <url> | sh -s -- --compiler-only   # compiler only (de-emphasized)

REPO_OWL="${OWL_REPO:-mire-lang/owl}"
REPO_COMPILER="${COMPILER_REPO:-mire-lang/Avenys-rust}"
REPO_KIOTO="${KIOTO_REPO:-mire-lang/Kioto}"
TARBALL="mire-linux-x86_64.tar.gz"
PREFIX=""
TAG_OWL=""
TAG_COMPILER=""
TAG_KIOTO=""
YES=0
NO_PROFILE=0
INSTALL_COMPILER=0
INSTALL_OWL=1
INSTALL_KIOTO=1
COMPILER_ONLY=0
KIOTO_ONLY=0

usage() {
    cat <<'USAGE'
Mire Toolchain Install

Usage:
  install.sh [options]

Options:
  --yes, -y             Non-interactive (skip confirmations)
  --prefix <path>        Install prefix (default: /usr/local)
  --compiler             Also install the Mire compiler
  --compiler-only        Install compiler only (de-emphasized)
  --kioto-only           Install kioto stdlib only (sets up ~/.owl/)
  --owl-only             Install owl only (no compiler, no kioto unless needed)
  --no-profile           Skip shell profile PATH modification
  --tag-owl <tag>        Specific owl release tag (default: latest)
  --tag-compiler <tag>   Specific compiler release tag (default: latest)
  --tag-kioto <tag>      Specific kioto release tag (default: latest)
  --help, -h             Show this help

Examples:
  curl https://.../install.sh | sh                     # install owl + kioto (default)
  curl https://.../install.sh | sh -s -- --compiler     # install owl + kioto + compiler
  curl https://.../install.sh | sh -s -- --compiler-only # compiler only
  curl https://.../install.sh | sh -s -- --kioto-only    # kioto only, sets up ~/.owl/
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y)             YES=1; shift ;;
        --prefix)              PREFIX="$2"; shift 2 ;;
        --compiler)            INSTALL_COMPILER=1; shift ;;
        --compiler-only)        COMPILER_ONLY=1; INSTALL_OWL=0; INSTALL_KIOTO=0; shift ;;
        --kioto-only)           KIOTO_ONLY=1; INSTALL_COMPILER=0; shift ;;
        --owl-only)             INSTALL_OWL=1; INSTALL_KIOTO=0; INSTALL_COMPILER=0; shift ;;
        --no-profile)          NO_PROFILE=1; shift ;;
        --tag-owl)              TAG_OWL="$2"; shift 2 ;;
        --tag-compiler)         TAG_COMPILER="$2"; shift 2 ;;
        --tag-kioto)            TAG_KIOTO="$2"; shift 2 ;;
        --help|-h)              usage; exit 0 ;;
        --)                     shift; break ;;
        -*)                     echo "error: unknown option: $1" >&2; usage; exit 1 ;;
        *)                      echo "error: unexpected argument: $1" >&2; usage; exit 1 ;;
    esac
done

if [ -z "$PREFIX" ]; then
    PREFIX="${MIRE_PREFIX:-/usr/local}"
fi

case "$PREFIX" in
    ~/*) PREFIX="${HOME}${PREFIX#~}" ;;
    ~)   PREFIX="${HOME}" ;;
esac

BIN_DIR="${PREFIX}/bin"
LIB_DIR="${PREFIX}/lib/mire"
OWL_HOME="$HOME/.owl"

banner() {
    echo ""
    echo "┌─ Mire Toolchain Install ─────────────────────────────────────────┐"
    echo "│ prefix: ${PREFIX}"
    if [ "$KIOTO_ONLY" = "1" ]; then
        echo "│ mode:   kioto only (stdlib)"
    elif [ "$COMPILER_ONLY" = "1" ]; then
        echo "│ mode:   compiler only"
    elif [ "$INSTALL_COMPILER" = "1" ]; then
        echo "│ mode:   owl + kioto + compiler (full)"
    elif [ "$INSTALL_OWL" = "1" ] && [ "$INSTALL_KIOTO" = "1" ]; then
        echo "│ mode:   owl + kioto (default)"
    elif [ "$INSTALL_OWL" = "1" ]; then
        echo "│ mode:   owl only"
    else
        echo "│ mode:   compiler only"
    fi
    echo "└──────────────────────────────────────────────────────────────────┘"
}

banner

if [ ! -t 0 ]; then
    { exec </dev/tty; } 2>/dev/null || true
fi

needs_sudo() {
    case "$PREFIX" in
        /usr|/usr/local|/opt*|/etc*) return 0 ;;
        *) return 1 ;;
    esac
}

detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "none"
    fi
}

install_deps() {
    local pm="$1"
    echo ""
    echo "  installing: curl tar clang llvm libssl libsdl2 openssl"
    echo "  manager: ${pm}"

    if [ "$YES" != "1" ]; then
        read -r -p "  proceed? [Y/n] " ans
        case "$ans" in
            [nN]*) echo "  skipping dependency install"; return ;;
        esac
    fi

    case "$pm" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y -qq curl tar clang llvm-dev libssl-dev libsdl2-dev 2>/dev/null || \
            sudo apt-get install -y -qq curl tar clang llvm-18-dev libssl-dev libsdl2-dev 2>/dev/null || \
            sudo apt-get install -y -qq curl tar clang libssl-dev libsdl2-dev
            ;;
        pacman)
            sudo pacman -Sy --noconfirm curl tar clang llvm openssl sdl2
            ;;
        dnf|yum)
            sudo "$pm" install -y curl tar clang llvm-devel openssl-devel SDL2-devel
            ;;
        apk)
            sudo apk add curl tar clang llvm-dev openssl-dev sdl2-dev
            ;;
        zypper)
            sudo zypper install -y curl tar clang llvm-devel libopenssl-devel libSDL2-devel
            ;;
    esac
}

check_prerequisites() {
    local missing=""
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing="$missing curl"
    fi
    if ! command -v tar >/dev/null 2>&1; then
        missing="$missing tar"
    fi

    if [ -z "$missing" ]; then
        return 0
    fi

    local pm
    pm="$(detect_pkg_manager)"

    if [ "$pm" = "none" ]; then
        echo ""
        echo "  warning: missing:${missing}"
        echo "  install these and re-run."
        return 0
    fi

    install_deps "$pm"
}

get_latest_tag() {
    local repo="$1"
    local tag=""
    if command -v curl >/dev/null 2>&1; then
        tag="$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
    elif command -v wget >/dev/null 2>&1; then
        tag="$(wget -qO- "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
    fi
    echo "$tag"
}

if [ "$COMPILER_ONLY" = "1" ]; then
    if [ -z "$TAG_COMPILER" ]; then
        TAG_COMPILER="$(get_latest_tag "$REPO_COMPILER")"
    fi
else
    if [ -z "$TAG_COMPILER" ] && [ "$INSTALL_COMPILER" = "1" ]; then
        TAG_COMPILER="$(get_latest_tag "$REPO_COMPILER")"
    fi
fi

check_prerequisites

install_file() {
    local src="$1" dst="$2"
    if needs_sudo; then
        sudo mkdir -p "$(dirname "$dst")"
        sudo cp "$src" "$dst"
        sudo chmod +x "$dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        chmod +x "$dst"
    fi
}

install_dir() {
    local src="$1"
    local name
    name="$(basename "$src")"
    if needs_sudo; then
        sudo mkdir -p "${LIB_DIR}"
        sudo rm -rf "${LIB_DIR}/${name}"
        sudo cp -r "$src" "${LIB_DIR}/"
    else
        mkdir -p "${LIB_DIR}"
        rm -rf "${LIB_DIR}/${name}"
        cp -r "$src" "${LIB_DIR}/"
    fi
}

detect_shell_profile() {
    local sh
    sh="$(basename "${SHELL:-/bin/sh}")"
    case "$sh" in
        zsh)  echo "${ZDOTDIR:-$HOME}/.zshrc" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        bash)
            if [ -f "$HOME/.bash_profile" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

OWL_BIN=""
COMPILER_BIN=""

# ── Kioto only ───────────────────────────────────────────────────────
if [ "$KIOTO_ONLY" = "1" ]; then
    echo ""
    echo "  ── Installing kioto stdlib ───────────────────────────────────"
    echo ""

    if [ "$YES" != "1" ]; then
        echo "  Will install:"
        echo "    • kioto stdlib   → ${OWL_HOME}/modules/kioto/"
        echo "    • owl home       → ${OWL_HOME}/"
        echo ""
        read -r -p "  continue? [Y/n] " ans
        case "$ans" in
            [nN]*) echo "  aborted."; exit 0 ;;
        esac
    fi

    mkdir -p "${OWL_HOME}/modules" "${OWL_HOME}/tmp"

    if [ ! -f "$OWL_HOME/config.toml" ]; then
        cat > "$OWL_HOME/config.toml" << 'CONFIG'
[owl]
version = "1.0.0"

[modules]
path = "~/.owl/modules"

[download]
timeout = 30
retry = 3
CONFIG
        echo "  created ${OWL_HOME}/config.toml"
    fi

    TAG_KIOTO="${TAG_KIOTO:-$(get_latest_tag "$REPO_KIOTO")}"
    echo "  downloading kioto ${TAG_KIOTO:-latest}..."

    set -e
    cd "$TMPDIR"
    rm -rf kioto-clone
    if command -v git >/dev/null 2>&1; then
        git clone --depth 1 --branch "${TAG_KIOTO:-main}" "https://github.com/${REPO_KIOTO}" kioto-clone 2>/dev/null || \
            git clone --depth 1 "https://github.com/${REPO_KIOTO}" kioto-clone
    else
        echo "  error: git is required for kioto-only install"
        exit 1
    fi

    rm -rf "${OWL_HOME}/modules/kioto"
    cp -r kioto-clone "${OWL_HOME}/modules/kioto"

    echo "  installed kioto to ${OWL_HOME}/modules/kioto/"
    echo ""
    echo "  ─────────────────────────────────────────────────────────────────"
    echo "  kioto install complete"
    echo ""
    echo "  To use kioto, add to your owl.toml sources path:"
    echo "    sources = \"code,/root/.owl/modules/kioto/core\""
    echo ""
    exit 0
fi

# ── Install owl (primary) ─────────────────────────────────────────────
echo ""
echo "  ── Installing owl ──────────────────────────────────────────────"
echo ""

if [ "$YES" != "1" ] && [ "$INSTALL_OWL" = "1" ]; then
    echo "  Will install:"
    echo "    • owl (pm)       → ${BIN_DIR}/owl"
    if [ "$INSTALL_KIOTO" = "1" ]; then
        echo "    • kioto stdlib   → ${OWL_HOME}/modules/kioto/"
    fi
    echo "    • owl home       → ${OWL_HOME}/"
    if needs_sudo; then
        echo ""
        echo "  sudo needed for system install."
    fi
    echo ""
    read -r -p "  continue? [Y/n] " ans
    case "$ans" in
        [nN]*) echo "  aborted."; exit 0 ;;
    esac
fi

URL_COMPILER="https://github.com/${REPO_COMPILER}/releases/download/${TAG_COMPILER:-latest}/${TARBALL}"

echo "  downloading compiler release..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$URL_COMPILER" -o "$TMPDIR/$TARBALL" 2>/dev/null || \
        curl -fsSL "https://github.com/${REPO_COMPILER}/releases/download/${TAG_COMPILER:-v0.1.0}/${TARBALL}" -o "$TMPDIR/$TARBALL"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$URL_COMPILER" -O "$TMPDIR/$TARBALL" 2>/dev/null || \
        wget -q "https://github.com/${REPO_COMPILER}/releases/download/${TAG_COMPILER:-v0.1.0}/${TARBALL}" -O "$TMPDIR/$TARBALL"
fi

if [ ! -f "$TMPDIR/$TARBALL" ] || [ ! -s "$TMPDIR/$TARBALL" ]; then
    echo "  error: could not download compiler release"
    echo "  (pre-built compiler releases may not be available yet)"
    echo "  Build from source: https://github.com/${REPO_COMPILER}"
    COMPILER_AVAILABLE=0
else
    COMPILER_AVAILABLE=1
    echo "  extracting..."
    tar xzf "$TMPDIR/$TARBALL" -C "$TMPDIR"

    if [ -f "$TMPDIR/mire/owl" ]; then
        mkdir -p "${BIN_DIR}"
        install_file "$TMPDIR/mire/owl" "${BIN_DIR}/owl"
        OWL_BIN="${BIN_DIR}/owl"
    fi

    if [ -d "$TMPDIR/mire/kioto" ] && [ "$INSTALL_KIOTO" = "1" ]; then
        mkdir -p "${OWL_HOME}/modules" "${OWL_HOME}/tmp"
        rm -rf "${OWL_HOME}/modules/kioto"
        cp -r "$TMPDIR/mire/kioto" "${OWL_HOME}/modules/kioto"
    fi

    if [ ! -f "$OWL_HOME/config.toml" ]; then
        mkdir -p "$OWL_HOME"
        cat > "$OWL_HOME/config.toml" << 'CONFIG'
[owl]
version = "1.0.0"

[modules]
path = "~/.owl/modules"

[download]
timeout = 30
retry = 3
CONFIG
    fi
fi

# ── Install compiler (optional / secondary) ──────────────────────────
if [ "$INSTALL_COMPILER" = "1" ] || [ "$COMPILER_ONLY" = "1" ]; then
    echo ""
    echo "  ── Installing Mire compiler ──────────────────────────────────"
    echo ""

    if [ "$YES" != "1" ]; then
        echo "  Will install:"
        echo "    • Mire compiler  → ${BIN_DIR}/mire"
        echo "    • Mire runtime   → ${LIB_DIR}/"
        if needs_sudo; then
            echo ""
            echo "  sudo needed for system install."
        fi
        echo ""
        read -r -p "  continue? [Y/n] " ans
        case "$ans" in
            [nN]*) echo "  skipped compiler install." ;;
        esac
    fi

    if [ "$COMPILER_AVAILABLE" = "1" ] && [ -f "$TMPDIR/mire/mire" ]; then
        install_file "$TMPDIR/mire/mire" "${BIN_DIR}/mire"
        COMPILER_BIN="${BIN_DIR}/mire"

        if [ -d "$TMPDIR/mire/runtime" ]; then
            install_dir "$TMPDIR/mire/runtime"
        fi
        if [ -d "$TMPDIR/mire/pal" ]; then
            install_dir "$TMPDIR/mire/pal"
        fi
    else
        echo "  compiler release not available."
        echo "  Build from source:"
        echo "    git clone https://github.com/${REPO_COMPILER}"
        echo "    cd ${REPO_COMPILER}"
        echo "    cargo build --release"
        echo "    sudo cp target/release/mire /usr/local/bin/mire"
    fi
fi

# ── PATH setup ────────────────────────────────────────────────────────
if [ "$NO_PROFILE" != "1" ] && [ "$COMPILER_ONLY" != "1" ]; then
    PROFILE_FILE="$(detect_shell_profile)"

    case ":$PATH:" in
        *":$BIN_DIR:"*)
            echo ""
            echo "  ${BIN_DIR} already in PATH"
            ;;
        *)
            echo ""
            echo "  adding ${BIN_DIR} to PATH"

            if [ "$YES" != "1" ]; then
                read -r -p "  modify ${PROFILE_FILE}? [Y/n] " ans
                case "$ans" in
                    [nN]*) echo "  skipped." ;;
                esac
            fi

            BACKUP="${PROFILE_FILE}.owl-backup-$(date +%Y%m%d-%H%M%S)"
            if [ -f "$PROFILE_FILE" ]; then
                cp "$PROFILE_FILE" "$BACKUP"
            else
                touch "$PROFILE_FILE"
            fi
            echo "  backup: ${BACKUP}"

            cat >> "$PROFILE_FILE" << PATHLINE

# added by Mire install script
export PATH="${BIN_DIR}:\$PATH"
PATHLINE
            echo "  updated ${PROFILE_FILE}"
            echo "  run: source ${PROFILE_FILE}"
            ;;
    esac
fi

# ── Done ──────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────────────────────"
echo "  install complete"
echo ""
if [ -n "$OWL_BIN" ] && [ -f "$OWL_BIN" ]; then
    echo "  owl:  ${OWL_BIN}"
    "$OWL_BIN" -V 2>/dev/null || true
fi
if [ -n "$COMPILER_BIN" ] && [ -f "$COMPILER_BIN" ]; then
    echo "  mire: ${COMPILER_BIN}"
    "$COMPILER_BIN" --version 2>/dev/null || true
fi
echo ""
if [ "$COMPILER_ONLY" != "1" ]; then
    echo "  try:"
    if [ -n "$OWL_BIN" ] && [ -f "$OWL_BIN" ]; then
        echo "    owl --help"
        echo "    owl new my-project"
    fi
    echo ""
    echo "  Need the compiler?"
    echo "    curl ... | sh -s -- --compiler"
fi
echo ""
