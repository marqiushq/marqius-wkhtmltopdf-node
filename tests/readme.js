// Prints the README's code block that follows "<!-- NAME -->", exactly as printed:
//   node tests/readme.js "example: wkhtmltopdf"
const fs = require("fs");
const path = require("path");
const readme = fs.readFileSync(path.join(__dirname, "..", "README.md"), "utf8").replace(/\r\n/g, "\n");
const marker = `<!-- ${process.argv[2]} -->`;
const at = readme.indexOf(marker);
const m = at < 0 ? null : /^\s*```[a-z]*\n([\s\S]*?)\n```/.exec(readme.slice(at + marker.length));
if (!m) {
  console.error(`README.md has no code block after ${marker}`);
  process.exit(1);
}
process.stdout.write(m[1] + "\n");
