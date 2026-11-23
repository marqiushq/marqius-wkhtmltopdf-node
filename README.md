# wkhtmltopdf for Node.js: marqius-wkhtmltopdf for the wkhtmltopdf and wkhtmltoimage packages

[![npm](https://img.shields.io/npm/v/marqius-wkhtmltopdf)](https://www.npmjs.com/package/marqius-wkhtmltopdf)

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, installed with npm.** Install it with one command, give your library its path in one line, and the `wkhtmltopdf` and `wkhtmltoimage` packages turn your HTML into PDFs and pictures as before. It prints Arabic, Hebrew, Hindi, Thai, Chinese, Japanese and Korean as well as English, on Linux, Mac and Windows.

- **One command to install.** No apt packages, no libssl 1.1, no X server, no Qt, and no install script: npm installs the program for your computer.
- **Your templates stay as they are.** The same HTML, the same options, the same package.
- **Many languages, even on one page.** Arabic and Hebrew from right to left, Indian and Asian scripts, all as text you can search and copy.
- **Fast.** A one-page invoice takes a few milliseconds.
- **Tested in public.** Every version is tested with the `wkhtmltopdf` and `wkhtmltoimage` packages on Linux, macOS and Windows before it is published.

## Make your first PDF in two minutes

**1. Install** the package and `wkhtmltopdf`, the most used Node package for wkhtmltopdf. Run this in your project, or in an empty folder:

<!-- quickstart -->
```bash
npm install marqius-wkhtmltopdf wkhtmltopdf
```

**2. Save** this as `invoice.js`:

<!-- example: quickstart invoice.js -->
```js
const wkhtmltopdf = require("wkhtmltopdf");
wkhtmltopdf.command = require("marqius-wkhtmltopdf").path;

wkhtmltopdf("<h1>Invoice 42</h1><p>Thank you for your order.</p>", { output: "invoice.pdf" });
```

**3. Run** it, then open `invoice.pdf`:

<!-- run -->
```bash
node invoice.js
```

That's it. Next, connect your code, or [print other languages](#which-languages-can-it-print).

## What do I change in my code?

| You use | What to do |
|---|---|
| The `wkhtmltopdf` package | [Set `wkhtmltopdf.command`](#how-do-i-use-it-with-the-wkhtmltopdf-package) |
| The `wkhtmltoimage` package | [Call `setCommand`](#how-do-i-make-pictures-with-wkhtmltoimage) |
| Your own `child_process` call | [Run the path it gives](#how-do-i-run-wkhtmltopdf-from-node-without-a-library) |
| ES modules or TypeScript | [Import it](#can-i-use-it-from-an-es-module-or-typescript) |

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

## How do I run wkhtmltopdf from Node without a library?

Run the path as you would run wkhtmltopdf, with `execFile`, `spawn` or `execFileSync`. A `-` in place of the page reads the HTML from the input:

<!-- example: child_process -->
```js
const { execFileSync } = require("child_process");
const { path } = require("marqius-wkhtmltopdf");

execFileSync(path, ["-", "invoice.pdf"], { input: "<h1>Invoice 42</h1>" });
```

## Can I use it from an ES module or TypeScript?

Yes. The package comes with its own types, and `marqius.path` is the same path:

<!-- example: import -->
```js
import marqius from "marqius-wkhtmltopdf";
```

## Which languages can it print?

All of these, even on one page. Each one is tested on real invoices, letters and receipts, and the PDF keeps the words as text, so you can search and copy them.

| Language | On a Linux server | On a Mac or Windows |
|---|---|---|
| English, French, German, Spanish and other languages in Latin letters; Greek; Russian | Works with the fonts most servers have | Works |
| Arabic and Hebrew, from right to left | Works: the fonts are built in | Works |
| Hindi and Thai | Install `fonts-noto-core` | Works |
| Chinese, Japanese and Korean | Install `fonts-noto-cjk` | Works |

On Debian or Ubuntu, this one line installs the fonts for every language above:

<!-- fonts: debian -->
```bash
sudo apt-get update && sudo apt-get install -y fonts-noto-core fonts-noto-cjk
```

In a Dockerfile, put the same line after `RUN`, without `sudo`. On Alpine, Fedora, Red Hat or Arch, the program tells you the line for your system ([see below](#why-do-letters-show-as-boxes-or-blanks-in-my-pdf)).

Then one invoice can carry them all, here with the `wkhtmltopdf` package:

<!-- example: languages -->
```js
const wkhtmltopdf = require("wkhtmltopdf");
wkhtmltopdf.command = require("marqius-wkhtmltopdf").path;

const html = `<!doctype html>
<meta charset="utf-8">
<h1>Invoice 42</h1>
<p lang="ar" dir="rtl">فاتورة 42</p>
<p lang="he" dir="rtl">חשבונית 42</p>
<p lang="hi">चालान 42</p>
<p lang="th">ใบแจ้งหนี้ 42</p>
<p lang="zh">发票 42</p>
<p lang="ja">請求書 42</p>
<p lang="ko">청구서 42</p>
`;

wkhtmltopdf(html, { output: "invoice.pdf" });
```

For a page all in Arabic or Hebrew, put `dir="rtl"` on its `<html>` tag. The page then reads from the right, and its tables and lists turn to match.

## Why do letters show as boxes or blanks in my PDF?

The computer that makes the PDF has no font for them. On Linux, install the fonts [above](#which-languages-can-it-print). To see what is missing, convert your page with the program itself:

<!-- check -->
```bash
npx marqius-wkhtmltopdf page.html page.pdf
```

It names each letter it could not print, then gives the one line that installs fonts for them on your system: `apt-get` on Debian and Ubuntu, `apk` on Alpine, `dnf` on Fedora and Red Hat, `pacman` on Arch.

## Why can't I search or copy Arabic, Chinese or Hindi text in my wkhtmltopdf PDF?

wkhtmltopdf often stores these scripts as shapes, not words. The public parity suite prints the same pages with both programs:

- **Arabic:** from wkhtmltopdf's invoice, 2 of its 56 words read back as written; from marqius-wkhtmltopdf's, 48.
- **Hebrew:** wkhtmltopdf splits many words into single letters (28 of 48 read back); marqius-wkhtmltopdf gives back 43.
- **Chinese:** wkhtmltopdf puts look-alike signs in place of some characters, so a search for the company's name finds nothing. marqius-wkhtmltopdf keeps the real characters.
- **Hindi and Thai:** wkhtmltopdf loses letters and splits off marks. marqius-wkhtmltopdf's text reads back clean.

The pages themselves look the same. [See every page and score](https://github.com/marqiushq/wkhtmltopdf-parity).

## Why are accented letters garbled, like Ã© for é?

Your page does not say that it is UTF-8, so wkhtmltopdf reads it as an old Western character set. marqius-wkhtmltopdf prints é, € and ü as written anyway. To make every program agree, put `<meta charset="utf-8">` at the top of your page.

## Why do I get "wkhtmltopdf: command not found"?

The `wkhtmltopdf` package runs a program called `wkhtmltopdf` through bash, and your machine has none. Install this package and set `wkhtmltopdf.command` to its path, as shown above.

## Why does wkhtmltopdf fail with "libssl.so.1.1: cannot open shared object file"?

Your wkhtmltopdf was built for an older system. It needs OpenSSL 1.1, which Debian 13 and Ubuntu 24.04 no longer include. marqius-wkhtmltopdf needs no system libraries, so it runs there as it is.

## Is it faster than wkhtmltopdf?

Yes. The public parity suite converts 86 documents with both programs on the same machine. marqius-wkhtmltopdf is 35 times faster, or 5 times faster with wkhtmltopdf's 200 ms wait for scripts turned off for both. On Linux, a one-page invoice takes 5 to 7 milliseconds. [See the results](https://github.com/marqiushq/wkhtmltopdf-parity).

## Will my PDFs look the same as with wkhtmltopdf?

Almost always. Of the parity suite's 86 documents, 64 come out the same, and 16 differ only in small details of appearance. Each difference is listed with its reason. To check your own templates, make a PDF with each program and compare them:

```bash
npx marqius-wkhtmltopdf compare old.pdf new.pdf
```

## Which systems does it run on?

It runs on:

- Linux on x64 and arm64, with glibc or musl, so Debian 13, Ubuntu 24.04 and Alpine too;
- Macs with Apple silicon;
- Windows on x64.

npm installs the right package for each, a download of about 10 MB. It needs no X server, Qt or system libraries. In a slim or Alpine image without fonts, the program says so and prints the one line that installs them. There is no build for Macs with Intel chips: there, `require` says so.

## Is marqius-wkhtmltopdf free?

You can try it free for 30 days. Personal, teaching and open-source use is free with a [Community licence](https://marqius.com/wkhtmltopdf-buy/#community): sign in with Google and your free key is waiting in your account.

Anything done by or for a business, including internal tools and client work, needs a paid plan once the trial ends. [See the plans and prices](https://marqius.com/licence/marqius-wkhtmltopdf).

Your PDFs never stop. Without a licence after the trial, each page carries one line, "Prepared by Marqius, Purchase Licence". [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## How do I add my licence key?

Set the `MARQIUS_LICENCE` environment variable to your licence; that is the way for containers and CI. Or save it as `licence.txt` and run `npx marqius-wkhtmltopdf licence add licence.txt`. `npx marqius-wkhtmltopdf licence` shows the trial's days left, or the licence in force.

## Does the wkhtmltopdf package pass its own tests?

Yes. The `wkhtmltopdf` package passes its own test suite with marqius-wkhtmltopdf, all 5 of its tests. The results are public: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests).

Before each version of this package is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-node/blob/main/.github/workflows/release.yml) installs it with npm and runs the examples on this page, the eight-language invoice among them, on Linux (x64 and arm64), macOS and Windows.

## How do I update it?

Run this in your project. It installs the newest version with your project's package manager: npm, pnpm, yarn or bun:

<!-- update -->
```bash
npx marqius-wkhtmltopdf update
```

`npm install marqius-wkhtmltopdf@latest` does the same. Each version of this package carries the marqius-wkhtmltopdf release with the same number, after testing it.

## What else does the program do?

`npx marqius-wkhtmltopdf` runs it under its own name:

- `npx marqius-wkhtmltopdf help node` shows each library's setting;
- `npx marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf;
- `npx marqius-wkhtmltopdf install` gives it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, with the rights to write to `/usr/local/bin`.

## Where do I get help?

Write to hello@marqius.com, or [open an issue](https://github.com/marqiushq/marqius-wkhtmltopdf-node/issues). Send the page that prints differently from wkhtmltopdf if you can.

This package's own JavaScript files are under the MIT licence: [LICENSE.md](LICENSE.md).
