---
name: han-scan-to-word
description: Analyze and convert scanned files, image-only PDFs or photographed documents (png, jpg, tif, bmp) into editable Word (.docx) files using Vietnamese OCR (Tesseract). Use when the user wants to convert a scanned PDF to Word, OCR a document, extract text from a scan or a photo, asks why text in a PDF cannot be copied, or wants to edit the content of a legal document downloaded with han-download-law-doc - even if they never say "OCR" or "Word".
compatibility: Windows 10/11 (64-bit) with Windows PowerShell 5.1 (powershell.exe, not pwsh 7). Tesseract OCR 5 and the Vietnamese language data are installed by the skill into the user's profile on first use (needs internet access to github.com), or an existing installation is used. No administrator rights, Python or Microsoft Word required.
---

# Convert scanned files and image PDFs to Word

This skill renders each PDF page to an image with the PDF renderer built into
Windows, recognizes the text with Tesseract OCR (Vietnamese model), merges the
recognized lines into paragraphs, and writes a `.docx` file. Neither Python nor
Microsoft Word is needed.

Reply to the user in the language they use.

Everything goes through `scripts/scan2word.ps1` (path relative to this skill
folder). Always run it with `powershell.exe` (version 5.1), because PowerShell 7
cannot load the Windows PDF renderer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill folder>\scripts\scan2word.ps1" <action> ...
```

## Workflow

### 0. Ask which file, if none was given

If the user invokes the skill without pointing to a file (for example only the
skill name `han-scan-to-word`, or "convert a scanned file to Word for me"), ask one
short question: which file do they want converted - the path to a PDF or an image.
Do not choose a file from the folder on their behalf, even if there is only one PDF:
converting the wrong document wastes time and can leave them with a Word file they
believe belongs to another document.

A reasonable exception: if exactly one file was just downloaded or mentioned in the
conversation and the user says "convert that file to Word", that is the file they
mean. If they give a folder or an incomplete name and several files match, list the
matches and let them choose.

### 1. Check that the machine is ready (`check`)

```powershell
... scan2word.ps1 check
```

This command is read-only, takes under a second, and is the first step of every use
of the skill.

**Result `READY` (exit code 0): go straight to step 2.** Do not mention
installation, do not run `setup`, and do not ask the user anything about Tesseract.
Once a machine is set up, the user should not have to hear about setup again every
time they convert a file.

**Result `NOT READY` (exit code 3):** the `missing:` line says what is absent
(`tesseract`, `language-data:vie`, or both). Ask the user **once** which option they
prefer, with enough information to decide:

- **Option 1 - the skill installs it (recommended).** Downloads a portable Tesseract
  together with the Vietnamese data (a zip of about 47 MB from the Releases of the
  `nguyenquanicd/VLSIT_Company_Manager_AI_Skills` repository) and unpacks it into
  `%LOCALAPPDATA%\han-scan-to-word` (about 130 MB). No administrator rights, no
  system settings touched, removed by deleting that folder. Run it only after the
  user agrees:

  ```powershell
  ... scan2word.ps1 setup
  ```

- **Option 2 - the user installs it.** They run the command below (Windows asks for
  administrator rights) and tell you when it is done; then you run `setup` to fetch
  the missing Vietnamese data (12 MB from `github.com/tesseract-ocr/tessdata_best`):

  ```powershell
  winget install --id UB-Mannheim.TesseractOCR -e
  ```

After either option, run `check` again and confirm `READY` before continuing. Do not
treat the user saying "installed" as sufficient - `check` is the evidence.

`setup` installs only what is missing: on a machine that is already set up it
prints `Already set up - nothing to do` and downloads nothing. Running it again by
accident is harmless, but there is no reason to run it once `check` reports `READY`.

If `setup` reports `Portable Tesseract NOT installed`:

- download error (404, no network, GitHub blocked by a firewall): fall back to
  Option 2, or, if the user already has the zip (copied by USB or from a network
  share), run `setup -BundlePath "<path to zip>"`;
- `does not match the expected SHA-256`: the downloaded file is not the published
  one. Do not try to bypass this check; tell the user and use Option 2.

Do not attempt to use the OCR engine built into Windows (Windows.Media.Ocr, or
`Add-WindowsCapability ... Language.OCR~~~vi-VN`): it has no Vietnamese model, and
that install command can never succeed. Do not use `-Language eng` as a stopgap for
Vietnamese documents either - all diacritics are lost ("lao động" becomes "Iao
döng") and the result is unusable. `-Language` takes Tesseract codes: `vie`
(default), `eng`, or a combination such as `vie+eng` for bilingual documents; each
code needs `setup -Language <code>` once.

### 2. Analyze the file (`analyze`)

```powershell
... scan2word.ps1 analyze -Path "C:\...\45.signed.pdf"
```

Reports the file type, page count, page size and a `Verdict`:

| Verdict | Meaning | What to do |
|---|---|---|
| `scan` | Pages are images with no text layer | Convert with OCR (step 3) |
| `mixed` | Very little real text (digital-signature labels, page numbers) on top of images | Still convert with OCR |
| `text` | The PDF already has real, selectable text | **Do not OCR** - see below |

Report the analysis to the user in a sentence or two before converting, especially
the page count: a document of several hundred pages takes a long time, and they
should know in advance.

**When the verdict is `text`**: running OCR over a document that already contains
text only introduces errors. Tell the user the file is not a scan, and that the best
route is to open the PDF directly in Microsoft Word (File > Open, select the PDF)
and Save As `.docx` - Word keeps the exact wording and most of the formatting. Add
`-OcrTextPdf` only if they still want OCR (for example when the PDF's text layer is
broken and copies out as garbage characters).

### 3. Convert (`convert`)

```powershell
... scan2word.ps1 convert -Path "C:\...\45.signed.pdf" -SaveText
... scan2word.ps1 convert -Path "C:\...\scan.jpg" -OutFile "C:\...\result.docx"
... scan2word.ps1 convert -Path "C:\...\45.signed.pdf" -Pages "1-5,8"
```

| Parameter | Meaning |
|---|---|
| `-Path` | A PDF or an image (`.png .jpg .jpeg .bmp .tif .tiff .gif`). Multi-page TIFFs are processed page by page. |
| `-OutFile` | Where to save the Word file. Default: same folder and name as the source, with the `.docx` extension. |
| `-Pages` | Convert only some pages, for example `1-5,8`. Useful for a quick trial on the first pages of a long document before running all of it. |
| `-SaveText` | Also write a plain-text `.txt` (UTF-8) next to the Word file. Recommended: reading it is the fastest way for you to check quality. |
| `-Dpi` | Rendering resolution, default 300. Raise to 400 when the original print is very small. |
| `-Force` | Overwrite an existing output file. By default the script stops, so that a Word file the user has already edited by hand is not destroyed. |
| `-Json` | Emit the result as JSON. |

Tesseract works page by page and takes a few seconds per A4 page (an 83-page
document took about five minutes), so for documents of a few dozen pages or more,
run the command in the background, and try `-Pages 1-3` first to see the quality.

Exit codes: `0` success, `3` Tesseract or language data missing (from `check`), `4`
the PDF already has real text and was not converted, `1` any other error (with a
message).

### 4. Verify before reporting completion

OCR is never fully correct, so before replying:

- Skim the `.txt` file (the first few pages and one in the middle) to make sure the
  output is readable Vietnamese with diacritics, not garbage characters.
- Look at `Mean confidence` (Tesseract's own score, out of 100) and the
  `Low-confidence pages` line: pages below 75 usually contain many errors and need
  to be proofread against the original. Name those page numbers.
- Look at the `Nearly empty pages` line: pages where almost no text was recognized -
  usually blank pages, pages holding only a seal or signature, or scans too faint to
  read. Give those page numbers to the user.

## What the output looks like

The Word file uses A4, Times New Roman 14 pt, and margins in the style of Vietnamese
administrative documents. Lines are merged into paragraphs; centered lines (the
national motto, the document title, chapter names) stay centered; upper-case
headings and lines beginning "Điều ..." (Article), "Chương ..." (Chapter) or
"Mục ..." (Section) are set in bold. Each source page starts on a new page of the
Word file, so the user can compare page against page.

## What to be honest about with the user

- **This is a working copy, not the authoritative text.** OCR confuses tone marks,
  look-alike characters (`l`/`1`/`I`, `0`/`O`) and digits - the most dangerous kind
  of error in a legal document, where article and clause numbers, amounts and dates
  are all digits. Always remind the user to check important figures and quotations
  against the original PDF, and to cite from the original.
- **Tables are not rebuilt.** Table content comes out as lines of text with columns
  separated by tabs; the user has to redraw the table if they need one.
- **Images, seals, signatures, italics and original font sizes are not kept.** Only
  the text and a basic paragraph layout.
- **A poor scan gives a poor result.** Skewed or faint pages, handwriting, and text
  overprinted by a red seal come out with many errors. If quality is poor, say so
  plainly and suggest finding a clearer scan, rather than handing over an
  error-ridden Word file without warning.
- **Digital-signature labels** at the top of page 1 of `.signed.pdf` files (the line
  "Ký bởi: Cổng Thông tin điện tử Chính phủ ...") are recognized as text as well.
  They are not part of the document; tell the user to delete them if not needed.

## When the script reports an error

- `Tesseract OCR is not installed ...` or `Tesseract language data ... is missing`:
  go back to step 1.
- `Tesseract failed ...`: read the accompanying message; usually a damaged image or
  an unusual image format. Try saving the image as PNG and run again.
- `Run this script with Windows PowerShell 5.1 ...`: it was started with `pwsh`;
  switch to `powershell.exe`.
- `Windows could not open this PDF ...`: the file is damaged or password-protected.
  Ask the user for the password or another copy; do not try to break the protection.
- `Output already exists ...`: ask whether to overwrite (`-Force`) or save under
  another name (`-OutFile`).
- `Unsupported file type ...`: only PDFs and images are accepted. Word or Excel
  files do not need this skill.
