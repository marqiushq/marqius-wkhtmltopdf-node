"use strict";
// marqius-wkhtmltopdf for Node: require("marqius-wkhtmltopdf").path is the installed program's
// path, to give the wkhtmltopdf package (or another library that runs wkhtmltopdf). npm installs
// the program for this machine with this package, from the optional dependency that matches it;
// nothing is downloaded at install.
// marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial:
// https://marqius.com/licence/marqius-wkhtmltopdf
const fs = require("fs");
const os = require("os");
const path = require("path");
const { version } = require("./package.json");

const BUILDS = {
  "linux x64": "marqius-wkhtmltopdf-linux-x64",
  "linux arm64": "marqius-wkhtmltopdf-linux-arm64",
  "darwin arm64": "marqius-wkhtmltopdf-darwin-arm64",
  "win32 x64": "marqius-wkhtmltopdf-win32-x64",
};

const windows = process.platform === "win32";

// the folder holding the program, in the package npm installed for this platform
function folder() {
  const here = `${process.platform} ${process.arch}`;
  const pkg = BUILDS[here];
  if (!pkg) {
    let why = `marqius-wkhtmltopdf has no build for ${here}: it runs on Linux (x64 and arm64), Apple silicon Macs and Windows (x64).`;
    if (here === "darwin x64") {
      why += " On a Mac with Apple silicon, use Node for Apple silicon rather than Node for Intel; for Intel Macs, write to hello@marqius.com.";
    }
    throw new Error(why);
  }
  try {
    return path.join(path.dirname(require.resolve(`${pkg}/package.json`)), "bin");
  } catch (e) {
    throw new Error(
      `marqius-wkhtmltopdf cannot find ${pkg}, which holds the program for ${here}. npm installs it with ` +
        `marqius-wkhtmltopdf unless optional dependencies are left out (--omit=optional, --no-optional) or the ` +
        `lockfile was made on another platform without it. Run "npm install marqius-wkhtmltopdf" again on this machine.`
    );
  }
}

// On Windows, the program answers to wkhtmltopdf.exe and wkhtmltoimage.exe by their file names:
// hard links beside it (copies where links cannot be made). Elsewhere a few lines of sh in the
// package start it under each name.
function named(dir, name) {
  if (!windows) {
    return path.join(dir, name);
  }
  const program = path.join(dir, "marqius-wkhtmltopdf.exe");
  const size = fs.statSync(program).size;
  for (const place of [dir, path.join(os.tmpdir(), `marqius-wkhtmltopdf-${version}`)]) {
    const to = path.join(place, `${name}.exe`);
    try {
      if (fs.statSync(to).size === size) {
        return to;
      }
    } catch (e) {
      // not made yet
    }
    try {
      fs.mkdirSync(place, { recursive: true });
      try {
        fs.unlinkSync(to);
      } catch (e) {
        // nothing to replace
      }
      try {
        fs.linkSync(program, to);
      } catch (e) {
        fs.copyFileSync(program, to);
      }
      return to;
    } catch (e) {
      // this folder cannot be written: try the next
    }
  }
  throw new Error(`marqius-wkhtmltopdf cannot be given the name ${name}.exe: neither ${dir} nor ${os.tmpdir()} can be written`);
}

const dir = folder();

/** The release of marqius-wkhtmltopdf this package carries, such as "0.12.10". */
exports.version = version;
/** The installed program's path, as wkhtmltopdf: give it where a library asks for wkhtmltopdf. */
exports.path = named(dir, "wkhtmltopdf");
/** Its path as wkhtmltoimage, for pictures. */
exports.imagePath = named(dir, "wkhtmltoimage");
/** The program under its own name, marqius-wkhtmltopdf: help, licence, compare and install. */
exports.program = path.join(dir, windows ? "marqius-wkhtmltopdf.exe" : "marqius-wkhtmltopdf");
