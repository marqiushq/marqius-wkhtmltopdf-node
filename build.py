#!/usr/bin/env python3
"""Lays out the npm packages of one release of marqius-wkhtmltopdf.

    python3 build.py VERSION BUILDS OUT

BUILDS holds the release's builds, checked by `.github/release.py fetch` (its SHA256SUMS is checked
again here). OUT receives marqius-wkhtmltopdf/ and one package per platform, each ready for
`npm pack` or `npm publish`. The main package's version and its optional dependencies are set to
VERSION. Only the standard library is used.
"""
import hashlib
import json
import shutil
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MAIN = "marqius-wkhtmltopdf"
# build on marqius.com -> npm's os and cpu, and a name for people
PLATFORMS = {
    "linux-x86_64": ("linux", "x64", "Linux (x64)"),
    "linux-arm64": ("linux", "arm64", "Linux (arm64)"),
    "macos-arm64": ("darwin", "arm64", "macOS (Apple silicon)"),
    "windows-x86_64.exe": ("win32", "x64", "Windows (x64)"),
}

# Unix: a few lines of sh start the program under the names libraries run
LAUNCHER = """#!/bin/sh
# Runs marqius-wkhtmltopdf as {name}, for libraries given this file's path. npm does not put it on
# the PATH. marqius-wkhtmltopdf is commercial software with a 30-day free trial: marqius.com/wkhtmltopdf
self=$0
while [ -h "$self" ]; do
    link=$(readlink "$self")
    case $link in /*) self=$link ;; *) self=${{self%/*}}/$link ;; esac
done
case $self in */*) here=${{self%/*}} ;; *) here=. ;; esac
exec "$here/marqius-wkhtmltopdf" {name} "$@"
"""

PLATFORM_README = """# {name}

marqius-wkhtmltopdf {version} for {human}. npm installs it with the [marqius-wkhtmltopdf](https://www.npmjs.com/package/marqius-wkhtmltopdf) package, on {human} only; install that package rather than this one.

marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial. [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)
"""


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    version, builds, out = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3])
    sums = {}
    for line in (builds / "SHA256SUMS").read_text().splitlines():
        sha, name = line.split()
        sums[name] = sha
    main_src = HERE / MAIN
    meta = json.loads((main_src / "package.json").read_text())
    out.mkdir(parents=True, exist_ok=True)

    optional = {}
    for build, (os_, cpu, human) in PLATFORMS.items():
        src = builds / f"marqius-wkhtmltopdf-{build}"
        got = hashlib.sha256(src.read_bytes()).hexdigest()
        if sums.get(src.name) != got:
            sys.exit(f"{src} does not match SHA256SUMS")
        name = f"{MAIN}-{os_}-{cpu}"
        optional[name] = version
        dst = out / name
        if dst.exists():
            shutil.rmtree(dst)
        (dst / "bin").mkdir(parents=True)
        exe = "marqius-wkhtmltopdf.exe" if os_ == "win32" else "marqius-wkhtmltopdf"
        shutil.copyfile(src, dst / "bin" / exe)
        (dst / "bin" / exe).chmod(0o755)
        if os_ != "win32":
            for named in ("wkhtmltopdf", "wkhtmltoimage"):
                (dst / "bin" / named).write_text(LAUNCHER.format(name=named))
                (dst / "bin" / named).chmod(0o755)
        package = {
            "name": name,
            "version": version,
            "description": f"marqius-wkhtmltopdf for {human}, installed by the marqius-wkhtmltopdf package (commercial, 30-day trial)",
            "homepage": meta["homepage"],
            "repository": {"type": "git", "url": meta["repository"]["url"]},
            "license": meta["license"],
            "author": meta["author"],
            "os": [os_],
            "cpu": [cpu],
            "files": ["bin/", "LICENSE.md"],
            "preferUnplugged": True,
            "engines": meta["engines"],
        }
        (dst / "package.json").write_text(json.dumps(package, indent=2) + "\n")
        (dst / "README.md").write_text(PLATFORM_README.format(name=name, version=version, human=human))
        shutil.copyfile(main_src / "LICENSE.md", dst / "LICENSE.md")
        print(f"{name} {version}: {got}")

    dst = out / MAIN
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(main_src, dst, ignore=shutil.ignore_patterns("node_modules", "*.tgz"))
    shutil.copyfile(HERE / "README.md", dst / "README.md")
    meta["version"] = version
    meta["optionalDependencies"] = dict(sorted(optional.items()))
    (dst / "package.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"{MAIN} {version}")


if __name__ == "__main__":
    main()
