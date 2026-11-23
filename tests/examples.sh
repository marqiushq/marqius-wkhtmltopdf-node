#!/bin/sh
# Runs this README's lines exactly as printed, each in a new project that already uses the
# library, and checks what each one makes.
#
#   tests/examples.sh WORK [LIBRARY ...]
#
# LIBRARY is quickstart (the README's first three steps, in an empty folder), wkhtmltopdf,
# wkhtmltopdf-quoted, wkhtmltoimage, child_process, import, types (the package's types, as
# TypeScript reads them), languages (the README's eight-language invoice, after its fonts line on
# Debian and Ubuntu: every word must read back as written, and every letter must have a font) or
# update (the README's update line); all but types by default.
#
# Before the packages are on npm, MARQIUS_NPM_TARBALLS names a folder of the packed packages
# (npm pack), or several, separated by spaces: a test registry on this machine (tests/registry.js)
# serves them and passes every other package through from npm, so that the install line still
# runs as printed. EXPECT_VERSION, if set, is the version npm must install. For update,
# UPDATE_FROM is the version to install first (else the README's install line), and UPDATE_TO
# the newer one the registry has (else the version installed must already be the newest, and stay).
set -eu
pkg=$(cd "$(dirname "$0")/.." && pwd)
work=$1
shift
libraries=${*:-quickstart wkhtmltopdf wkhtmltopdf-quoted wkhtmltoimage child_process import languages update}
platform=$(node -p 'process.platform + "-" + process.arch')
say() { printf '\n== %s\n' "$*"; }
fail() {
    echo "FAIL $lib: $*" >&2
    exit 1
}
readme() { node "$pkg/tests/readme.js" "$1"; }

fresh() { # a new, empty folder for this library
    dir=$work/$lib
    rm -rf "$dir"
    mkdir -p "$dir"
    cd "$dir"
}

installed() { # the version of a package in this project's node_modules
    node -p "require('./node_modules/$1/package.json').version"
}

expected() { # the version EXPECT_VERSION names, if it names one, for the package and this platform's
    if [ -n "${EXPECT_VERSION:-}" ]; then
        for name in marqius-wkhtmltopdf "marqius-wkhtmltopdf-$platform"; do
            got=$(installed "$name") || fail "npm did not install $name"
            [ "$got" = "$EXPECT_VERSION" ] || fail "npm installed $name $got, not $EXPECT_VERSION"
        done
        echo "ok $lib: marqius-wkhtmltopdf $EXPECT_VERSION installed, with marqius-wkhtmltopdf-$platform"
    fi
}

project() { # a new project that uses the library already, then this README's install line
    fresh
    npm init -y >/dev/null
    [ $# -eq 0 ] || npm install --no-audit --no-fund "$@"
    line=$(readme install)
    say "$line"
    sh -c "$line" </dev/null
    expected
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

program_says() { # what the README's own line for it says of page.html's letters
    line=$(readme check)
    say "$line"
    sh -c "$line" >said.txt 2>&1 || true
    cat said.txt
}

if [ -n "${MARQIUS_NPM_TARBALLS:-}" ]; then
    mkdir -p "$work"
    rm -f "$work/registry.port"
    # shellcheck disable=SC2086 # (one folder or several, separated by spaces)
    node "$pkg/tests/registry.js" "$work/registry.port" $MARQIUS_NPM_TARBALLS &
    registry=$!
    trap 'kill $registry 2>/dev/null' EXIT
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$work/registry.port" ] && break; sleep 1; done
    export npm_config_registry="http://127.0.0.1:$(cat "$work/registry.port")/"
fi

for lib in $libraries; do
    say "$lib on $platform"
    case $lib in
    quickstart)
        # the README's three steps, as printed, in an empty folder
        fresh
        line=$(readme quickstart)
        say "$line"
        sh -c "$line" </dev/null
        expected
        readme "example: quickstart invoice.js" >invoice.js
        cat invoice.js
        line=$(readme run)
        say "$line"
        sh -c "$line" </dev/null
        check invoice.pdf %PDF-
        ;;
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
    child_process)
        # in a folder with a space in its path too: no shell is involved
        saved=$work
        work="$work/with space"
        project
        work=$saved
        readme "example: child_process" >render.js
        cat render.js
        node render.js
        check invoice.pdf %PDF-
        ;;
    import)
        project
        { readme "example: import"; echo 'import { execFileSync } from "child_process";'; echo 'process.stdout.write(execFileSync(marqius.path, ["-V"]));'; } >check.mjs
        cat check.mjs
        node check.mjs | grep "compatible; marqius-wkhtmltopdf" || fail "the imported path does not run wkhtmltopdf"
        ;;
    types)
        # the README's import, and each name the package gives, as TypeScript reads the package's types
        project typescript
        { readme "example: import"; printf 'import { version, path, imagePath, program } from "marqius-wkhtmltopdf";\nconst all: string[] = [marqius.path, marqius.imagePath, marqius.program, marqius.version, version, path, imagePath, program];\nconsole.log(all.length);\n'; } >check.mts
        cat check.mts
        npx --no-install tsc --noEmit --strict --module nodenext --moduleResolution nodenext check.mts || fail "TypeScript does not accept the package's types"
        echo "ok $lib: the types pass tsc --strict"
        ;;
    languages)
        project wkhtmltopdf
        readme "example: languages" >render.js
        cat render.js
        # the page in the README's example, as page.html for the program's own line
        node -e 'const s = require("fs").readFileSync("render.js", "utf8"); const m = /const html = `([\s\S]*?)`;/.exec(s); require("fs").writeFileSync("page.html", m[1]);'
        if [ -f /etc/debian_version ]; then
            # before the fonts: what the program says, and that it names Debian's Noto packages
            program_says
            if grep -q 'no font has a glyph' said.txt; then
                grep -q 'fonts-noto' said.txt || fail "the program named letters with no font, but no fonts-noto package to install"
            fi
            line=$(readme "fonts: debian")
            say "$line"
            sh -c "$line" >fonts.log 2>&1 || { cat fonts.log; fail "$line"; }
        fi
        node render.js
        check invoice.pdf %PDF-
        # every word as written
        if ! command -v pdftotext >/dev/null 2>&1; then
            if [ -f /etc/debian_version ]; then
                sudo apt-get install -y -qq poppler-utils >/dev/null || true
            elif [ "$(uname -s)" = Darwin ]; then
                brew install -q poppler >/dev/null || true
            fi
        fi
        command -v pdftotext >/dev/null 2>&1 || fail "no pdftotext to read the words back with"
        # UTF-8 said outright: the pdftotext that comes with Git on Windows writes Latin-1 otherwise
        pdftotext -enc UTF-8 invoice.pdf - >text.txt
        cat text.txt
        for word in 'Invoice 42' 'فاتورة' 'חשבונית' 'चालान' 'ใบแจ้งหนี้' '发票' '請求書' '청구서'; do
            grep -qF "$word" text.txt || fail "invoice.pdf does not read $word as written"
        done
        echo "ok $lib: every word reads back as written"
        # after the fonts, or with the system's own: no letter without a font
        program_says
        ! grep -q 'no font has a glyph' said.txt || fail "letters with no font on this system"
        ;;
    update)
        fresh
        npm init -y >/dev/null
        if [ -n "${UPDATE_FROM:-}" ]; then
            npm install --no-audit --no-fund "marqius-wkhtmltopdf@$UPDATE_FROM"
        else
            line=$(readme install)
            say "$line"
            sh -c "$line" </dev/null
        fi
        before=$(installed marqius-wkhtmltopdf)
        line=$(readme update)
        say "$line (from $before)"
        sh -c "$line" </dev/null >said.txt 2>&1 || { cat said.txt; fail "$line"; }
        cat said.txt
        got=$(installed marqius-wkhtmltopdf)
        if [ -n "${UPDATE_TO:-}" ]; then
            [ "$got" = "$UPDATE_TO" ] || fail "$line left $got, not $UPDATE_TO"
            [ "$(installed "marqius-wkhtmltopdf-$platform")" = "$UPDATE_TO" ] || fail "$line did not bring marqius-wkhtmltopdf-$platform $UPDATE_TO"
            grep -q "is now $UPDATE_TO" said.txt || fail "$line did not say that it is now $UPDATE_TO"
            grep -q "\"marqius-wkhtmltopdf\": \"^$UPDATE_TO\"" package.json || fail "package.json does not ask for $UPDATE_TO"
        else
            [ "$got" = "$before" ] || fail "$line changed $before to $got, where $before was the newest"
            grep -q "$before is the newest version" said.txt || fail "$line did not say that $before is the newest"
        fi
        echo "ok $lib: $before -> $got"
        ;;
    *)
        fail "no such library"
        ;;
    esac
    npx --no-install marqius-wkhtmltopdf --version | grep '^marqius-wkhtmltopdf [0-9]' || fail "npx marqius-wkhtmltopdf --version"
    node -e 'const m = require("marqius-wkhtmltopdf"); require("child_process").execFileSync(m.path, ["-V"], {stdio: "inherit"})' | grep "compatible; marqius-wkhtmltopdf" || fail "the path -V"
done
say "all passed: $libraries on $platform"
