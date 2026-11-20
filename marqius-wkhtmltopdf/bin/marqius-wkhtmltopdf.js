#!/usr/bin/env node
"use strict";
// marqius-wkhtmltopdf under its own name (npx marqius-wkhtmltopdf): help, licence, compare,
// install and wkhtmltopdf's command line. Commercial software with a 30-day free trial.
const { spawnSync } = require("child_process");

let program;
try {
  program = require("..").program;
} catch (e) {
  console.error(`marqius-wkhtmltopdf: ${e.message}`);
  process.exit(1);
}
const run = spawnSync(program, process.argv.slice(2), { stdio: "inherit" });
if (run.error) {
  console.error(`marqius-wkhtmltopdf: ${run.error.message}`);
  process.exit(1);
}
if (run.signal) {
  process.kill(process.pid, run.signal);
}
process.exit(run.status === null ? 1 : run.status);
