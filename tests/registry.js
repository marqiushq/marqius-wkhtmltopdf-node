// A read-only npm registry on this machine, for testing the packages before npm has them.
//
//   node tests/registry.js TARBALLS PORTFILE
//
// Serves every package packed in TARBALLS (npm pack) under its own name, on 127.0.0.1 at a free
// port, which it writes to PORTFILE; every other package is passed through, read-only, from
// registry.npmjs.org. With npm_config_registry pointing at it, `npm install marqius-wkhtmltopdf`
// runs as printed. It runs until it is stopped. Node's own modules only.
"use strict";
const crypto = require("crypto");
const fs = require("fs");
const http = require("http");
const https = require("https");
const path = require("path");
const zlib = require("zlib");

const [folder, portfile] = process.argv.slice(2);
const UPSTREAM = "https://registry.npmjs.org";

// package/package.json from a packed tarball (a gzipped tar: 512-byte headers, then the file)
function manifest(tgz) {
  const tar = zlib.gunzipSync(tgz);
  for (let at = 0; at + 512 <= tar.length; ) {
    const name = tar.toString("utf8", at, at + 100).replace(/\0.*$/s, "");
    const size = parseInt(tar.toString("utf8", at + 124, at + 136).replace(/\0.*$/s, "").trim() || "0", 8);
    if (!name) break;
    if (name === "package/package.json") return JSON.parse(tar.toString("utf8", at + 512, at + 512 + size));
    at += 512 + Math.ceil(size / 512) * 512;
  }
  throw new Error("no package/package.json in a tarball");
}

const docs = {};
const server = http.createServer((req, res) => {
  const want = decodeURIComponent(req.url.split("?")[0]).replace(/^\/+/, "");
  const send = (status, body, type = "application/json") => {
    res.writeHead(status, { "Content-Type": type, "Content-Length": body.length });
    res.end(body);
  };
  if (want.startsWith("-/tarballs/")) {
    const file = path.join(folder, path.basename(want));
    return fs.existsSync(file) ? send(200, fs.readFileSync(file), "application/octet-stream") : send(404, Buffer.from("{}"));
  }
  if (docs[want]) return send(200, Buffer.from(JSON.stringify(docs[want])));
  https
    .get(UPSTREAM + req.url, { headers: { accept: req.headers.accept || "application/json" } }, (up) => {
      const parts = [];
      up.on("data", (d) => parts.push(d));
      up.on("end", () => send(up.statusCode, Buffer.concat(parts), up.headers["content-type"] || "application/json"));
    })
    .on("error", (e) => send(502, Buffer.from(JSON.stringify({ error: e.message }))));
});

server.listen(0, "127.0.0.1", () => {
  const base = `http://127.0.0.1:${server.address().port}`;
  for (const file of fs.readdirSync(folder).filter((f) => f.endsWith(".tgz")).sort()) {
    const tgz = fs.readFileSync(path.join(folder, file));
    const m = manifest(tgz);
    m.dist = {
      tarball: `${base}/-/tarballs/${file}`,
      shasum: crypto.createHash("sha1").update(tgz).digest("hex"),
      integrity: "sha512-" + crypto.createHash("sha512").update(tgz).digest("base64"),
    };
    const doc = (docs[m.name] = docs[m.name] || { name: m.name, "dist-tags": {}, versions: {} });
    doc.versions[m.version] = m;
    doc["dist-tags"].latest = m.version;
  }
  fs.writeFileSync(portfile, String(server.address().port));
  console.log(`test registry on ${base}/ for ${Object.keys(docs).sort().join(", ")}`);
});
