#!/usr/bin/env node
"use strict";
// marqius-wkhtmltopdf under its own name (npx marqius-wkhtmltopdf): help, licence, compare,
// install and wkhtmltopdf's command line. `update` updates this package itself, in the project
// that depends on it, with that project's package manager (npm, pnpm, yarn or bun).
// Commercial software with a 30-day free trial.
const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const NAME = "marqius-wkhtmltopdf";
const windows = process.platform === "win32";

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    return null;
  }
}

// The project that depends on this package: the first folder up, outside node_modules, whose
// package.json names it. With which section names it.
function project(pkgDir) {
  for (let dir = path.dirname(pkgDir); dir !== path.dirname(dir); dir = path.dirname(dir)) {
    if (dir.split(path.sep).includes("node_modules")) continue;
    const json = readJson(path.join(dir, "package.json"));
    if (!json) continue;
    for (const section of ["dependencies", "devDependencies", "optionalDependencies"]) {
      if (json[section] && json[section][NAME]) return { dir, section };
    }
  }
  return null;
}

// The package manager the project uses, by its lock file, else by what started this command.
function manager(dir) {
  const has = (f) => fs.existsSync(path.join(dir, f));
  if (has("pnpm-lock.yaml")) return "pnpm";
  if (has("yarn.lock")) return "yarn";
  if (has("bun.lock") || has("bun.lockb")) return "bun";
  if (has("package-lock.json") || has("npm-shrinkwrap.json")) return "npm";
  const agent = (process.env.npm_config_user_agent || "").split("/")[0];
  return ["pnpm", "yarn", "bun"].includes(agent) ? agent : "npm";
}

function run(command, args, cwd) {
  // (npm, pnpm and yarn are .cmd files on Windows, which only a shell starts)
  const r = spawnSync(command, args, { cwd, stdio: "inherit", shell: windows });
  if (r.error) {
    console.error(`marqius-wkhtmltopdf: ${command}: ${r.error.message}`);
    return 1;
  }
  return r.status === null ? 1 : r.status;
}

function update() {
  const pkgDir = path.dirname(__dirname);
  const before = readJson(path.join(pkgDir, "package.json")).version;
  const found = project(pkgDir);
  let command;
  let args;
  let cwd;
  let after;
  if (found) {
    command = manager(found.dir);
    const flag = {
      devDependencies: { npm: "--save-dev", pnpm: "--save-dev", yarn: "--dev", bun: "--dev" },
      optionalDependencies: { npm: "--save-optional", pnpm: "--save-optional", yarn: "--optional", bun: "--optional" },
    }[found.section];
    args = [command === "npm" ? "install" : "add", `${NAME}@latest`].concat(flag ? [flag[command]] : []);
    cwd = found.dir;
    after = path.join(found.dir, "node_modules", NAME, "package.json");
  } else {
    // installed with npm install --global, or by another package: then only npm's global folder is ours to update
    const root = spawnSync("npm", ["root", "--global"], { encoding: "utf8", shell: windows });
    const global = root.status === 0 && root.stdout.trim();
    if (!global || path.resolve(global) !== path.resolve(path.dirname(pkgDir))) {
      console.error(
        `marqius-wkhtmltopdf: no package.json above ${pkgDir} names ${NAME}, so it came with another package. ` +
          `Add it to your project, then update it there:\n\n    npm install ${NAME}@latest`
      );
      return 1;
    }
    command = "npm";
    args = ["install", "--global", `${NAME}@latest`];
    cwd = process.cwd();
    after = path.join(pkgDir, "package.json");
  }
  const shown = `${command} ${args.join(" ")}`;
  console.log(`${NAME} ${before}: looking for a newer version (${shown}${found ? `, in ${cwd}` : ""})`);
  const status = run(command, args, cwd);
  if (status !== 0) {
    console.error(`${NAME} was not updated: ${shown} failed.`);
    return status;
  }
  const now = (readJson(after) || {}).version;
  if (now === before) {
    console.log(`${NAME} ${before} is the newest version.`);
  } else {
    console.log(`${NAME} is now ${now}.`);
  }
  return 0;
}

if (process.argv.slice(2).join(" ") === "update") {
  process.exit(update());
}

let program;
try {
  program = require("..").program;
} catch (e) {
  console.error(`marqius-wkhtmltopdf: ${e.message}`);
  process.exit(1);
}
const runProgram = spawnSync(program, process.argv.slice(2), { stdio: "inherit" });
if (runProgram.error) {
  console.error(`marqius-wkhtmltopdf: ${runProgram.error.message}`);
  process.exit(1);
}
if (runProgram.signal) {
  process.kill(process.pid, runProgram.signal);
}
process.exit(runProgram.status === null ? 1 : runProgram.status);
