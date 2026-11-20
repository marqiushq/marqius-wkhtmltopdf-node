# marqius-wkhtmltopdf for Node

**marqius-wkhtmltopdf** is the maintained drop-in replacement for wkhtmltopdf. This npm package brings it to your project for the `wkhtmltopdf` package and other Node libraries that run wkhtmltopdf: keep your library, your HTML templates and your PDF calls, and point the library at it with one line. It runs on Linux (x64 and arm64, glibc and musl), Apple silicon Macs and Windows (x64), and needs no X server, Qt or system libraries.

<!-- install -->
```bash
npm install marqius-wkhtmltopdf
```

npm installs the program for your platform from a matching optional dependency, as it does for esbuild: nothing is downloaded by an install script, so it works with `--ignore-scripts`, private registries and offline caches.

On a server or in a container without fonts, such as a slim or Alpine image, the program says so and prints the one line that installs them for that system.

## Point your library at it

`require("marqius-wkhtmltopdf").path` is the installed program's path: give it to your library where it asks for wkhtmltopdf, and `.imagePath` where it asks for wkhtmltoimage. Each is a path inside `node_modules`; nothing is installed under the name `wkhtmltopdf` on your system.

### wkhtmltopdf

Where your code has `const wkhtmltopdf = require("wkhtmltopdf");`:

<!-- example: wkhtmltopdf -->
```js
wkhtmltopdf.command = require("marqius-wkhtmltopdf").path;
wkhtmltopdf("<h1>Invoice 42</h1>", { output: "invoice.pdf" });
```

On Linux and macOS this package starts the program through a shell. If your project's folder has a space in its path, put the path in single quotes:

<!-- example: wkhtmltopdf quoted -->
```js
wkhtmltopdf.command = "'" + require("marqius-wkhtmltopdf").path + "'";
```

### wkhtmltoimage

Where your code has `const wkhtmltoimage = require("wkhtmltoimage");`:

<!-- example: wkhtmltoimage -->
```js
wkhtmltoimage.setCommand(require("marqius-wkhtmltopdf").imagePath);
wkhtmltoimage.generate("<h1>Invoice 42</h1>", { output: "invoice.jpg" });
```

### With import

In an ES module, `marqius.path` is the same path:

<!-- example: import -->
```js
import marqius from "marqius-wkhtmltopdf";
```

## The program itself

`npx marqius-wkhtmltopdf` runs it under its own name: `npx marqius-wkhtmltopdf help node` shows each library's setting, `npx marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf, and `npx marqius-wkhtmltopdf licence` shows the trial days left.

To give it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, as the [one-line installer](https://marqius.com/wkhtmltopdf/download/) does, run `npx marqius-wkhtmltopdf install` with the rights to write to `/usr/local/bin`.

## Always the latest release

Each release of this package carries one release of marqius-wkhtmltopdf, with the same version number. [A workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-node/blob/main/.github/workflows/release.yml) follows marqius.com every hour: a new release is checked against its published checksums, installed with npm and run through the `wkhtmltopdf` package on Linux (x64 and arm64), macOS (Apple silicon) and Windows, and only then published. To move to it:

```bash
npm install marqius-wkhtmltopdf@latest
```

## Licence

marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial counted from its first run. After the trial, without a licence, each page carries one line saying the copy is unlicensed. [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## Before you switch

- [wkhtmltopdf parity suite](https://github.com/marqiushq/wkhtmltopdf-parity): the same HTML documents through wkhtmltopdf and marqius-wkhtmltopdf on every release, misses included.
- [The developer manual](https://marqius.com/download/developer-manual.pdf), one chapter per library, and [runnable examples](https://github.com/marqiushq/marqius-wkhtmltopdf-examples).
