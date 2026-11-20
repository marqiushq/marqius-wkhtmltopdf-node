#!/bin/sh
# Runs this README's install line and each library's example exactly as printed, each in a new
# project that already uses the library, and checks what each one makes.
#
#   tests/examples.sh WORK [LIBRARY ...]   LIBRARY: wkhtmltopdf, wkhtmltopdf-quoted, wkhtmltoimage or import
#
# Before the packages are on npm, MARQIUS_NPM_TARBALLS names a folder of the packed packages
# (npm pack): a test registry on this machine (tests/registry.js) serves them and passes every
# other package through from npm, so that the install line still runs as printed.
set -eu
pkg=$(cd "$(dirname "$0")/.." && pwd)
work=$1
shift
libraries=${*:-wkhtmltopdf wkhtmltopdf-quoted wkhtmltoimage import}
platform=$(node -p 'process.platform + "-" + process.arch')
say() { printf '\n== %s\n' "$*"; }
fail() {
    echo "FAIL $lib: $*" >&2
    exit 1
}
readme() { node "$pkg/tests/readme.js" "$1"; }

project() { # a new project that uses the library already, then this README's install line
    dir=$work/$lib
    rm -rf "$dir"
    mkdir -p "$dir"
    cd "$dir"
    npm init -y >/dev/null
    [ $# -eq 0 ] || npm install --no-audit --no-fund "$@"
    line=$(readme install)
    say "$line"
    sh -c "$line" </dev/null
}

check() { # a file made by the example, and its first bytes
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$1" ] && break; sleep 1; done
    [ -s "$1" ] || fail "no $1"
    head -c 8 "$1" | od -An -c | tr -d ' \n' | grep -q "$2" || fail "$1 does not start with $2"
    if [ "$2" = "%PDF-" ] && command -v pdftotext >/dev/null 2>&1; then
        pdftotext "$1" - | grep -q 'Invoice 42' || fail "$1 does not read Invoice 42"
    fi
    echo "ok $lib: $1 ($(wc -c <"$1" | tr -d ' ') bytes)"
}

if [ -n "${MARQIUS_NPM_TARBALLS:-}" ]; then
    mkdir -p "$work"
    rm -f "$work/registry.port"
    node "$pkg/tests/registry.js" "$MARQIUS_NPM_TARBALLS" "$work/registry.port" &
    registry=$!
    trap 'kill $registry 2>/dev/null' EXIT
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$work/registry.port" ] && break; sleep 1; done
    export npm_config_registry="http://127.0.0.1:$(cat "$work/registry.port")/"
fi

for lib in $libraries; do
    say "$lib on $platform"
    case $lib in
    wkhtmltopdf)
        project wkhtmltopdf
        { echo 'const wkhtmltopdf = require("wkhtmltopdf");'; readme "example: wkhtmltopdf"; } >render.js
        cat render.js
        node render.js
        check invoice.pdf %PDF-
        ;;
    wkhtmltopdf-quoted)
        # A project whose path has a space in it. On Linux and macOS the package runs the program
        # through a shell, so the README's quoted line is used; on Windows it runs the program
        # without one, so the README's plain lines must work as they are.
        saved=$work
        work="$work/with space"
        project wkhtmltopdf
        work=$saved
        if [ "$platform" = win32-x64 ]; then
            { echo 'const wkhtmltopdf = require("wkhtmltopdf");'; readme "example: wkhtmltopdf"; } >render.js
        else
            { echo 'const wkhtmltopdf = require("wkhtmltopdf");'; readme "example: wkhtmltopdf quoted"; readme "example: wkhtmltopdf" | tail -n 1; } >render.js
        fi
        cat render.js
        node render.js
        check invoice.pdf %PDF-
        ;;
    wkhtmltoimage)
        project wkhtmltoimage
        { echo 'const wkhtmltoimage = require("wkhtmltoimage");'; readme "example: wkhtmltoimage"; } >render.js
        cat render.js
        node render.js
        check invoice.jpg 377330377
        ;;
    import)
        project
        { readme "example: import"; echo 'import { execFileSync } from "node:child_process";'; echo 'process.stdout.write(execFileSync(marqius.path, ["-V"]));'; } >check.mjs
        cat check.mjs
        node check.mjs | grep "compatible; marqius-wkhtmltopdf" || fail "the imported path does not run wkhtmltopdf"
        ;;
    *)
        fail "no such library"
        ;;
    esac
    npx --no-install marqius-wkhtmltopdf --version | grep '^marqius-wkhtmltopdf [0-9]' || fail "npx marqius-wkhtmltopdf --version"
    node -e 'const m = require("marqius-wkhtmltopdf"); require("child_process").execFileSync(m.path, ["-V"], {stdio: "inherit"})' | grep "compatible; marqius-wkhtmltopdf" || fail "the path -V"
done
say "all passed: $libraries on $platform"
