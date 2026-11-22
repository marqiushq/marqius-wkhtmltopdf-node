# marqius-wkhtmltopdf: wkhtmltopdf for Node.js

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, as an npm package.** `npm install` it, give your library its path in one line, and the `wkhtmltopdf` and `wkhtmltoimage` packages keep making PDFs and pictures from your HTML. It runs on Linux (x64 and arm64, glibc and musl, including Debian 13, Ubuntu 24.04 and Alpine), Apple silicon Macs and Windows (x64).

## How do I install wkhtmltopdf with npm?

<!-- install -->
```bash
npm install marqius-wkhtmltopdf
```

npm installs the program for your platform from a matching optional dependency, as it does for esbuild. No install script downloads anything, so it works with `--ignore-scripts`, private registries and offline caches. It installs nothing under the name `wkhtmltopdf` on your system: your library gets the program's path from `require("marqius-wkhtmltopdf").path`, as below.

## How do I use it with the wkhtmltopdf package?

Give the package the path. Where your code has `const wkhtmltopdf = require("wkhtmltopdf");`:

<!-- example: wkhtmltopdf -->
```js
wkhtmltopdf.command = require("marqius-wkhtmltopdf").path;
wkhtmltopdf("<h1>Invoice 42</h1>", { output: "invoice.pdf" });
```

On Linux and macOS the `wkhtmltopdf` package starts the program through a shell. If your project's folder has a space in its path, put the path in single quotes:

<!-- example: wkhtmltopdf quoted -->
```js
wkhtmltopdf.command = "'" + require("marqius-wkhtmltopdf").path + "'";
```

## How do I make pictures with wkhtmltoimage?

Give it the path for pictures, `.imagePath`. Where your code has `const wkhtmltoimage = require("wkhtmltoimage");`:

<!-- example: wkhtmltoimage -->
```js
wkhtmltoimage.setCommand(require("marqius-wkhtmltopdf").imagePath);
wkhtmltoimage.generate("<h1>Invoice 42</h1>", { output: "invoice.jpg" });
```

## Can I use it from an ES module?

Yes. `marqius.path` is the same path:

<!-- example: import -->
```js
import marqius from "marqius-wkhtmltopdf";
```

## Why do I get "wkhtmltopdf: command not found"?

The `wkhtmltopdf` package runs a program called `wkhtmltopdf` through bash, and your machine has none. Install this package and set `wkhtmltopdf.command` to its path, as shown above.

## Why does wkhtmltopdf fail with "libssl.so.1.1: cannot open shared object file"?

Your wkhtmltopdf was built for an older system. It needs OpenSSL 1.1, which Debian 13 and Ubuntu 24.04 no longer include. marqius-wkhtmltopdf needs no system libraries, so it runs there as it is.

## Which systems does marqius-wkhtmltopdf run on?

It runs on:

- Linux on x64 and arm64, with glibc or musl (so Alpine too);
- Macs with Apple silicon;
- Windows on x64.

npm installs the right package for each. It needs no X server, Qt or system libraries. In a slim or Alpine image without fonts, the program says so and prints the one line that installs them.

## Is marqius-wkhtmltopdf free?

You can try it free for 30 days. Personal, teaching and open-source use is free with a [Community licence](https://marqius.com/wkhtmltopdf-buy/#community): sign in with Google and your free key is waiting in your account.

Anything done by or for a business, including internal tools and client work, needs Starter or above once the trial ends. Starter is $290 USD a year for organisations of up to 10 people, and Business $990 USD a year, plus applicable taxes.

Your PDFs never stop. Without a licence after the trial, each page carries one line, "Prepared by Marqius, Purchase Licence". [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## How do I add my licence key?

Set the `MARQIUS_LICENCE` environment variable to your licence; that is the way for containers and CI. Or save it as `licence.txt` and run `npx marqius-wkhtmltopdf licence add licence.txt`. `npx marqius-wkhtmltopdf licence` shows the trial's days left, or the licence in force.

## Does the wkhtmltopdf package pass its own tests?

Yes. The `wkhtmltopdf` package passes its own test suite with marqius-wkhtmltopdf, all 5 of its tests. The results are public: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests).

Before each version of this package is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-node/blob/main/.github/workflows/release.yml) installs it with npm and runs the examples on this page on Linux (x64 and arm64), macOS and Windows.

## How do I update it?

Each version of this package carries the marqius-wkhtmltopdf release with the same number. To move to the newest:

```bash
npm install marqius-wkhtmltopdf@latest
```

## What else does the program do?

`npx marqius-wkhtmltopdf` runs it under its own name:

- `npx marqius-wkhtmltopdf help node` shows each library's setting;
- `npx marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf;
- `npx marqius-wkhtmltopdf install` gives it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, with the rights to write to `/usr/local/bin`.

This package's own JavaScript files are under the MIT licence: [LICENSE.md](LICENSE.md).
