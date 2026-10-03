<#
.SYNOPSIS
    Analyze a scanned PDF / image and convert it to an editable Word (.docx) file,
    using the PDF renderer built into Windows and Tesseract OCR.

.DESCRIPTION
    Windows' own OCR has no Vietnamese model, which is why Tesseract is used.

    Actions:
      check    - report whether this machine is ready (Tesseract + language data)
      setup    - install whatever is missing into %LOCALAPPDATA%\han-scan-to-word
                 (portable Tesseract + language data; no administrator rights).
                 Does nothing when the machine is already set up.
      analyze  - inspect one file: page count, scan vs. real text layer
      convert  - render every page to an image, recognize the text, rebuild
                 paragraphs, and write the .docx

    A PDF that already has a real text layer is not converted (exit code 4):
    OCR would only degrade it. Pass -OcrTextPdf to force OCR anyway.

    Must run under Windows PowerShell 5.1 (powershell.exe): PowerShell 7 cannot
    load the Windows PDF renderer.

    This file is intentionally ASCII-only; Vietnamese letters inside patterns are
    built from code points so the script parses identically on any code page.

.EXAMPLE
    .\scan2word.ps1 check
    .\scan2word.ps1 analyze -Path .\45.signed.pdf
    .\scan2word.ps1 convert -Path .\45.signed.pdf -Pages 1-5
    .\scan2word.ps1 convert -Path .\scan.jpg -OutFile .\scan.docx -SaveText
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('check', 'setup', 'analyze', 'convert')]
    [string]$Action,

    [string]$Path,
    [string]$OutFile,

    # e.g. "1-5,8,10-12"; default = all pages
    [string]$Pages,

    # Tesseract language code(s); Vietnamese by default. Combine with '+', e.g. vie+eng
    [string]$Language = 'vie',

    # run OCR even though the PDF already has a real text layer
    [switch]$OcrTextPdf,

    [int]$Dpi = 300,

    # also write the recognized text as a UTF-8 .txt next to the .docx
    [switch]$SaveText,

    # setup: install from this local bundle zip instead of downloading it
    [string]$BundlePath,
    [switch]$Force,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

if ($PSVersionTable.PSVersion.Major -gt 5) {
    throw 'Run this script with Windows PowerShell 5.1 (powershell.exe), not pwsh: PowerShell 7 cannot load the Windows PDF renderer.'
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.InMemoryRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
$null = [Windows.Data.Pdf.PdfDocument, Windows.Data.Pdf, ContentType = WindowsRuntime]

# the language value ends up on the Tesseract command line, so keep it to plain codes
if ($Language -notmatch '^[A-Za-z_]+(\+[A-Za-z_]+)*$') { throw "Invalid -Language '$Language'. Use Tesseract codes such as vie, eng, or vie+eng." }

$ImageExtensions = '.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff', '.gif'

# --- WinRT async bridging ---------------------------------------------------

$script:asTaskOperation = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } |
    Select-Object -First 1
$script:asTaskAction = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } |
    Select-Object -First 1

function Wait-Operation {
    param($Operation, [Type]$ResultType)
    $task = $script:asTaskOperation.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
    $task.Wait() | Out-Null
    return $task.Result
}

function Wait-Action {
    param($AsyncAction)
    $task = $script:asTaskAction.Invoke($null, @($AsyncAction))
    $task.Wait() | Out-Null
}

# --- helpers ------------------------------------------------------------------

function Resolve-InputFile {
    if (-not $Path) { throw "$Action needs -Path." }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "File not found: $Path" }
    return (Resolve-Path -LiteralPath $Path).Path
}

function ConvertTo-PageList {
    param([string]$Spec, [int]$Count)
    if (-not $Spec) { return @(1..$Count) }
    $set = New-Object System.Collections.Generic.SortedSet[int]
    foreach ($part in ($Spec -split '[,;]')) {
        $p = $part.Trim()
        if (-not $p) { continue }
        if ($p -match '^(\d+)\s*-\s*(\d+)$') { $a = [int]$Matches[1]; $b = [int]$Matches[2] }
        elseif ($p -match '^\d+$') { $a = [int]$p; $b = $a }
        else { throw "Cannot read page range '$p'. Use a form like 1-5,8." }
        for ($i = $a; $i -le $b; $i++) { if ($i -ge 1 -and $i -le $Count) { [void]$set.Add($i) } }
    }
    if ($set.Count -eq 0) { throw "Page range '$Spec' selects nothing; the file has $Count page(s)." }
    return @($set)
}

function Open-Pdf {
    param([string]$FullPath)
    $file = Wait-Operation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($FullPath)) ([Windows.Storage.StorageFile])
    try {
        return Wait-Operation ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
    }
    catch {
        throw "Windows could not open this PDF (damaged or password-protected?): $($_.Exception.GetBaseException().Message)"
    }
}

function Get-PdfTextOperatorCount {
    # A scanned PDF is just one picture per page; a "real" PDF draws text with the
    # Tj / TJ operators inside its (usually Flate-compressed) content streams.
    # Counting those operators tells the two apart without any PDF library.
    param([string]$FullPath)
    $latin1 = [System.Text.Encoding]::GetEncoding(28591)
    $raw = $latin1.GetString([System.IO.File]::ReadAllBytes($FullPath))
    $count = 0
    $buffer = New-Object byte[] 262144
    foreach ($m in [regex]::Matches($raw, 'stream\r?\n')) {
        $start = $m.Index + $m.Length
        $dictStart = [Math]::Max(0, $m.Index - 400)
        $dict = $raw.Substring($dictStart, $m.Index - $dictStart)
        # pictures and fonts can never contain page text - skip them (also avoids false hits in binary data)
        if ($dict -match '/Subtype\s*/Image|/DCTDecode|/JPXDecode|/CCITTFaxDecode|/JBIG2Decode|/FontFile|/Length1') { continue }
        $end = $raw.IndexOf('endstream', $start)
        if ($end -lt 0) { continue }
        $text = $null
        if ($dict -match '/FlateDecode') {
            if ($end - $start -lt 3) { continue }
            try {
                # skip the 2-byte zlib header, inflate at most 256 KB per stream
                $bytes = $latin1.GetBytes($raw.Substring($start + 2, $end - $start - 2))
                $ms = New-Object System.IO.MemoryStream(, $bytes)
                $inflate = New-Object System.IO.Compression.DeflateStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
                $read = 0
                while ($read -lt $buffer.Length) {
                    $n = $inflate.Read($buffer, $read, $buffer.Length - $read)
                    if ($n -le 0) { break }
                    $read += $n
                }
                $inflate.Dispose(); $ms.Dispose()
                $text = $latin1.GetString($buffer, 0, $read)
            }
            catch { continue }
        }
        elseif ($end - $start -lt 2000000) {
            $text = $raw.Substring($start, $end - $start)
        }
        if ($text -and $text.Contains('BT')) {
            $count += [regex]::Matches($text, '[\)>]\s*Tj|\]\s*TJ').Count
        }
    }
    return $count
}

function Get-Analysis {
    param([string]$FullPath)
    $ext = [System.IO.Path]::GetExtension($FullPath).ToLowerInvariant()
    $sizeKb = [Math]::Round((Get-Item -LiteralPath $FullPath).Length / 1KB)
    if ($ImageExtensions -contains $ext) {
        return [pscustomobject][ordered]@{
            path = $FullPath; kind = 'image'; pages = 1; sizeKB = $sizeKb
            textOperatorsPerPage = 0; verdict = 'scan'; suggestedEngine = 'ocr'
            note = 'Image file: OCR is the only way to get text out of it.'
        }
    }
    if ($ext -ne '.pdf') { throw "Unsupported file type '$ext'. Supported: .pdf and images ($($ImageExtensions -join ', '))." }

    $pdf = Open-Pdf $FullPath
    $pageCount = [int]$pdf.PageCount
    $ops = Get-PdfTextOperatorCount $FullPath
    $perPage = [Math]::Round($ops / [Math]::Max(1, $pageCount), 1)

    if ($perPage -ge 15) {
        $verdict = 'text'
        $note = 'This PDF already contains real, selectable text, so OCR would only add mistakes. Open it directly in Microsoft Word (File > Open) and save as .docx. To run OCR on it anyway, add -OcrTextPdf.'
        $suggest = 'none'
    }
    elseif ($perPage -ge 2) {
        $verdict = 'mixed'
        $suggest = 'ocr'
        $note = 'Only a little real text was found (page stamps, digital-signature labels, or a few typed pages among scans). OCR is the safer choice.'
    }
    else {
        $verdict = 'scan'
        $suggest = 'ocr'
        $note = 'Pages are pictures with no text layer: OCR is required.'
    }
    $first = $pdf.GetPage(0)
    return [pscustomobject][ordered]@{
        path = $FullPath; kind = 'pdf'; pages = $pageCount; sizeKB = $sizeKb
        pageSizeMm = ('{0} x {1}' -f [Math]::Round($first.Size.Width / 96 * 25.4), [Math]::Round($first.Size.Height / 96 * 25.4))
        textOperatorsPerPage = $perPage; verdict = $verdict; suggestedEngine = $suggest; note = $note
    }
}

# --- OCR (Tesseract) ----------------------------------------------------------

# Everything the skill installs goes into one per-user folder, so setup never
# needs administrator rights and can be undone by deleting that folder.
$script:HomeDir = Join-Path $env:LOCALAPPDATA 'han-scan-to-word'
$script:EngineDir = Join-Path $script:HomeDir 'tesseract'
$script:DataDir = Join-Path $script:HomeDir 'tessdata'
$script:DataUrl = 'https://github.com/tesseract-ocr/tessdata_best/raw/main'

# Portable Tesseract bundle (tesseract.exe + the DLLs it needs + vie.traineddata),
# published as a release asset of this repository. The hash pins the exact file:
# a download that does not match is discarded instead of being unpacked.
$script:BundleUrl = 'https://github.com/nguyenquanicd/VLSIT_Company_Manager_AI_Skills/releases/download/tesseract-portable-5.4.0/tesseract-portable-5.4.0-win64.zip'
$script:BundleSha256 = '4102A025C4AADA5C6AD0707DCE357391B9B04844020607A473117F3AB96FA6C1'

function Find-Tesseract {
    # Order: the copy this skill installed, a copy shipped inside the skill folder,
    # then any system-wide installation the user already has.
    $candidates = @(
        (Join-Path $script:EngineDir 'tesseract.exe'),
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'bin\tesseract.exe'))
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $cmd = Get-Command tesseract.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs'), $env:LOCALAPPDATA) | Where-Object { $_ }
    foreach ($root in $roots) {
        $candidate = Join-Path $root 'Tesseract-OCR\tesseract.exe'
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Find-LanguageData {
    # Returns the folder that holds a .traineddata file for every requested
    # language ("vie+eng" needs both), or $null.
    param([string]$TesseractExe)
    $needed = $Language -split '\+'
    $dirs = @($script:DataDir)
    if ($TesseractExe) { $dirs += (Join-Path (Split-Path -Parent $TesseractExe) 'tessdata') }
    foreach ($dir in $dirs) {
        $missing = @($needed | Where-Object { -not (Test-Path -LiteralPath (Join-Path $dir "$_.traineddata")) })
        if ($missing.Count -eq 0) { return $dir }
    }
    return $null
}

function Get-SetupState {
    $tess = Find-Tesseract
    $dataFolder = Find-LanguageData $tess
    $version = $null
    if ($tess) { $version = [string](& $tess --version 2>$null | Select-Object -First 1) }
    $missing = @()
    if (-not $tess) { $missing += 'tesseract' }
    if (-not $dataFolder) { $missing += "language-data:$Language" }
    return [pscustomobject][ordered]@{
        ready              = [bool]($tess -and $dataFolder)
        tesseract          = $tess
        tesseractVersion   = $version
        language           = $Language
        languageDataFolder = $dataFolder
        missing            = $missing
    }
}

function Get-RemoteFile {
    param([string]$Url, [string]$Target)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $temp = "$Target.download"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Url, $temp)
        Move-Item -LiteralPath $temp -Destination $Target -Force
    }
    catch {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
        throw "Could not download $Url : $($_.Exception.GetBaseException().Message)"
    }
}

function Install-Bundle {
    # Unpacks the portable bundle into the per-user folder. Source is a local zip
    # (-BundlePath, e.g. copied by USB to a machine without internet) or the
    # release asset. Either way the SHA-256 must match before anything is unpacked.
    $zip = $BundlePath
    $downloaded = $false
    if (-not $zip) {
        if (-not (Test-Path -LiteralPath $script:HomeDir)) { [void](New-Item -ItemType Directory -Path $script:HomeDir -Force) }
        $zip = Join-Path $script:HomeDir 'bundle.zip'
        Get-RemoteFile -Url $script:BundleUrl -Target $zip
        $downloaded = $true
    }
    elseif (-not (Test-Path -LiteralPath $zip -PathType Leaf)) { throw "Bundle file not found: $zip" }

    try {
        $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
        if ($hash -ne $script:BundleSha256) {
            throw "The bundle does not match the expected SHA-256 (got $hash). It was not unpacked."
        }
        $archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $zip).Path)
        try {
            foreach ($entry in $archive.Entries) {
                if (-not $entry.Name) { continue }   # directory entry
                $relative = $entry.FullName -replace '/', '\'
                if ($relative -notmatch '^(tesseract|tessdata)\\[^\\]+$') { continue }   # nothing outside the two known folders
                $target = Join-Path $script:HomeDir $relative
                $folder = Split-Path -Parent $target
                if (-not (Test-Path -LiteralPath $folder)) { [void](New-Item -ItemType Directory -Path $folder -Force) }
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
            }
        }
        finally { $archive.Dispose() }
    }
    finally {
        if ($downloaded -and (Test-Path -LiteralPath $zip)) { Remove-Item -LiteralPath $zip -Force }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $script:EngineDir 'tesseract.exe'))) { throw 'The bundle was unpacked but tesseract.exe is missing from it.' }
}

function Invoke-Tesseract {
    param([string]$TesseractExe, [string]$DataFolder, [string]$Image, [string]$OutBase, [switch]$NoDpi)
    $arguments = "`"$Image`" `"$OutBase`" --tessdata-dir `"$($DataFolder.TrimEnd('\'))`" -l $Language --psm 3"
    if (-not $NoDpi) { $arguments += " --dpi $Dpi" }
    # Ask for TSV through a variable rather than the "tsv" config file: config
    # files are looked up inside --tessdata-dir, and our per-user folder has none.
    $arguments += ' -c tessedit_create_tsv=1'
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $TesseractExe
    $psi.Arguments = $arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardError = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath "$OutBase.tsv")) {
        throw "Tesseract failed (exit $($proc.ExitCode)): $($stderr.Trim())"
    }
}

function ConvertFrom-Tsv {
    # Tesseract's TSV lists every page / block / paragraph / line / word with its
    # box and a 0-100 confidence. Reduce it to one object per page holding plain
    # line records, which is all the layout code below needs.
    param([string]$TsvPath)
    $pages = @()
    $page = $null
    $lineMap = $null
    $rows = [System.IO.File]::ReadAllLines($TsvPath, [System.Text.Encoding]::UTF8)
    for ($i = 1; $i -lt $rows.Length; $i++) {
        $f = $rows[$i].Split("`t", 12)
        if ($f.Length -lt 11) { continue }
        $level = [int]$f[0]
        if ($level -eq 1) {
            $lineMap = [ordered]@{}
            $page = [pscustomobject]@{ width = [double]$f[8]; height = [double]$f[9]; lineMap = $lineMap; confSum = 0.0; confCount = 0 }
            $pages += $page
            continue
        }
        if ($null -eq $page) { continue }
        $key = "$($f[2])-$($f[3])-$($f[4])"
        if ($level -eq 4) {
            $lineMap[$key] = [pscustomobject]@{
                words = New-Object System.Collections.Generic.List[string]
                x0 = [double]::MaxValue; y0 = [double]::MaxValue; x1 = 0.0; y1 = 0.0; h = [double]$f[9]
            }
        }
        elseif ($level -eq 5 -and $lineMap.Contains($key)) {
            $text = if ($f.Length -ge 12) { $f[11].Trim() } else { '' }
            $conf = [double]$f[10]
            if (-not $text -or $conf -lt 0) { continue }
            $l = $lineMap[$key]
            $left = [double]$f[6]; $top = [double]$f[7]; $w = [double]$f[8]; $h = [double]$f[9]
            $l.words.Add($text)
            if ($left -lt $l.x0) { $l.x0 = $left }
            if ($top -lt $l.y0) { $l.y0 = $top }
            if ($left + $w -gt $l.x1) { $l.x1 = $left + $w }
            if ($top + $h -gt $l.y1) { $l.y1 = $top + $h }
            $page.confSum += $conf; $page.confCount++
        }
    }
    $result = @()
    foreach ($p in $pages) {
        $lines = @()
        foreach ($l in $p.lineMap.Values) {
            if ($l.words.Count -eq 0) { continue }
            $lines += [pscustomobject]@{ text = ($l.words -join ' '); x0 = $l.x0; y0 = $l.y0; x1 = $l.x1; y1 = $l.y1; h = [Math]::Max(1.0, $l.h) }
        }
        $confidence = if ($p.confCount -gt 0) { [Math]::Round($p.confSum / $p.confCount) } else { 0 }
        $result += [pscustomobject]@{ width = $p.width; height = $p.height; lines = $lines; confidence = $confidence }
    }
    return , $result
}

function Get-PageParagraphs {
    # Turn loose OCR lines into paragraphs. Rules of thumb for typed documents:
    #  - lines on the same baseline form one row (two-column letterheads become one
    #    row joined by a tab)
    #  - a row continues the previous paragraph when that previous row ran all the
    #    way to the right margin and the new row is not indented and does not open
    #    with a list/article marker
    #  - rows with equal white space left and right are centered headings
    param($Page)
    # Vietnamese structural words, spelled with code points to keep this file ASCII
    $dieu = "$([char]0x0110)i$([char]0x1EC1)u"                 # "Dieu"   (article)
    $chuong = "Ch$([char]0x01B0)$([char]0x01A1)ng"             # "Chuong" (chapter)
    $muc = "M$([char]0x1EE5)c"                                 # "Muc"    (section)
    $phan = "Ph$([char]0x1EA7)n"                               # "Phan"   (part)
    $phuLuc = "PH$([char]0x1EE4)\s+L$([char]0x1EE4)C"          # "PHU LUC" (appendix)
    $dStroke = [string][char]0x0111
    $headings = "^($dieu\s+\d+|$chuong\s+[IVXLCDM\d]+|$muc\s+[IVXLCDM\d]+)"
    $markers = "^($dieu\s+\d+|$chuong\s+[IVXLCDM\d]+|$muc\s+[IVXLCDM\d]+|$phan\s+|$phuLuc|\d+[\.\)]\s|[a-z$dStroke][\)\.]\s|[-+*]\s)"

    $lines = @($Page.lines | Sort-Object { ($_.y0 + $_.y1) / 2 })
    if ($lines.Count -eq 0) { return , @() }

    # 1. group lines into rows
    $rows = @()
    $current = @($lines[0])
    for ($i = 1; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        $rowCenter = (($current | ForEach-Object { ($_.y0 + $_.y1) / 2 }) | Measure-Object -Average).Average
        if ([Math]::Abs((($l.y0 + $l.y1) / 2) - $rowCenter) -lt 0.6 * $l.h) { $current += $l }
        else { $rows += , $current; $current = @($l) }
    }
    $rows += , $current

    $rowObjects = @()
    foreach ($segs in $rows) {
        $segs = @($segs | Sort-Object x0)
        $text = $segs[0].text
        $multi = $false
        for ($k = 1; $k -lt $segs.Count; $k++) {
            if ($segs[$k].x0 - $segs[$k - 1].x1 -gt 3 * $segs[$k].h) { $text += "`t" + $segs[$k].text; $multi = $true }
            else { $text += ' ' + $segs[$k].text }
        }
        $rowObjects += [pscustomobject]@{
            text = $text; multi = $multi
            x0 = ($segs | Measure-Object x0 -Minimum).Minimum
            x1 = ($segs | Measure-Object x1 -Maximum).Maximum
            y0 = ($segs | Measure-Object y0 -Minimum).Minimum
            y1 = ($segs | Measure-Object y1 -Maximum).Maximum
            h  = ($segs | Measure-Object h -Average).Average
        }
    }

    # 2. text block margins, taken from the wide rows so stray marks do not distort them
    $wide = @($rowObjects | Where-Object { ($_.x1 - $_.x0) -gt 0.5 * $Page.width })
    if ($wide.Count -eq 0) { $wide = $rowObjects }
    $left = ($wide | Measure-Object x0 -Minimum).Minimum
    $right = ($wide | Measure-Object x1 -Maximum).Maximum
    $span = [Math]::Max(1.0, $right - $left)

    # 3. rows -> paragraphs
    $paragraphs = @()
    $prevRow = $null
    foreach ($r in $rowObjects) {
        $gapLeft = $r.x0 - $left
        $gapRight = $right - $r.x1
        $centered = (-not $r.multi) -and ($gapLeft -gt 0.08 * $span) -and ([Math]::Abs($gapLeft - $gapRight) -lt 0.08 * $span)
        $indented = $gapLeft -gt 0.03 * $span
        $isMarker = $r.text -match $markers

        $join = $false
        if ($prevRow -and $paragraphs.Count -gt 0) {
            $last = $paragraphs[$paragraphs.Count - 1]
            $prevFull = ($right - $prevRow.x1) -lt 0.06 * $span
            $near = ($r.y0 - $prevRow.y1) -lt 1.0 * $r.h
            if (-not $last.centered -and -not $last.multi -and -not $centered -and -not $r.multi -and
                -not $indented -and -not $isMarker -and $prevFull -and $near) { $join = $true }
        }

        if ($join) {
            $last.text = $last.text + ' ' + $r.text
            $last.rows++
        }
        else {
            $letters = [regex]::Replace($r.text, '[^\p{L}]', '')
            $allCaps = $letters.Length -ge 3 -and $letters -ceq $letters.ToUpper()
            $paragraphs += [pscustomobject]@{
                text = $r.text; rows = 1; centered = $centered; multi = $r.multi
                indent = ($indented -and -not $centered -and -not $r.multi)
                bold = (($centered -and $allCaps) -or ($r.text -match $headings))
            }
        }
        $prevRow = $r
    }
    return , $paragraphs
}

function Invoke-Ocr {
    param([string]$FullPath, $Analysis)
    $tess = Find-Tesseract
    if (-not $tess) { throw "Tesseract OCR is not installed. Run this script with 'check' to see how to install it." }
    $dataFolder = Find-LanguageData $tess
    if (-not $dataFolder) { throw "Tesseract language data for '$Language' is missing. Run this script with 'setup' to download it." }

    $work = Join-Path ([System.IO.Path]::GetTempPath()) ('scan2word_' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $work -Force)
    $pagesOut = @()
    try {
        if ($Analysis.kind -eq 'image') {
            # work on an ASCII-named copy: Tesseract on Windows can choke on accented paths
            $copy = Join-Path $work ('input' + [System.IO.Path]::GetExtension($FullPath).ToLowerInvariant())
            Copy-Item -LiteralPath $FullPath -Destination $copy
            $base = Join-Path $work 'input'
            Invoke-Tesseract -TesseractExe $tess -DataFolder $dataFolder -Image $copy -OutBase $base -NoDpi
            $n = 0
            foreach ($page in (ConvertFrom-Tsv "$base.tsv")) {
                $n++
                $pagesOut += [pscustomobject]@{ number = $n; paragraphs = (Get-PageParagraphs $page); confidence = $page.confidence }
            }
            return , $pagesOut
        }

        $pdf = Open-Pdf $FullPath
        foreach ($number in (ConvertTo-PageList -Spec $Pages -Count ([int]$pdf.PageCount))) {
            $pdfPage = $pdf.GetPage([uint32]($number - 1))
            $options = New-Object Windows.Data.Pdf.PdfPageRenderOptions
            $options.DestinationWidth = [uint32][Math]::Floor($pdfPage.Size.Width * $Dpi / 96.0)
            $options.DestinationHeight = [uint32][Math]::Floor($pdfPage.Size.Height * $Dpi / 96.0)

            $stream = New-Object Windows.Storage.Streams.InMemoryRandomAccessStream
            Wait-Action ($pdfPage.RenderToStreamAsync($stream, $options))
            $png = Join-Path $work "page.png"
            $reader = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($stream.GetInputStreamAt(0))
            $fs = [System.IO.File]::Create($png)
            $reader.CopyTo($fs)
            $fs.Dispose(); $reader.Dispose(); $stream.Dispose(); $pdfPage.Dispose()

            $base = Join-Path $work 'page'
            Invoke-Tesseract -TesseractExe $tess -DataFolder $dataFolder -Image $png -OutBase $base
            $page = @(ConvertFrom-Tsv "$base.tsv")[0]
            if ($null -eq $page) { $page = [pscustomobject]@{ width = 1; height = 1; lines = @(); confidence = 0 } }
            $pagesOut += [pscustomobject]@{ number = $number; paragraphs = (Get-PageParagraphs $page); confidence = $page.confidence }
            Remove-Item -LiteralPath $png, "$base.tsv" -Force -ErrorAction SilentlyContinue
        }
        return , $pagesOut
    }
    finally {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --- DOCX writer --------------------------------------------------------------

function ConvertTo-XmlText {
    param([string]$Text)
    $t = [System.Security.SecurityElement]::Escape($Text)
    # characters that are illegal in XML 1.0 would make Word reject the file
    return [regex]::Replace($t, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
}

function Write-Docx {
    param($PageList, [string]$Target)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    [void]$sb.Append('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>')
    $first = $true
    foreach ($page in $PageList) {
        if (-not $first) { [void]$sb.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>') }
        $first = $false
        foreach ($p in $page.paragraphs) {
            [void]$sb.Append('<w:p><w:pPr>')
            if ($p.centered) { [void]$sb.Append('<w:jc w:val="center"/>') }
            elseif ($p.rows -gt 1) { [void]$sb.Append('<w:jc w:val="both"/>') }
            if ($p.indent) { [void]$sb.Append('<w:ind w:firstLine="567"/>') }
            [void]$sb.Append('</w:pPr>')
            $parts = $p.text -split "`t"
            for ($i = 0; $i -lt $parts.Count; $i++) {
                [void]$sb.Append('<w:r>')
                if ($p.bold) { [void]$sb.Append('<w:rPr><w:b/></w:rPr>') }
                if ($i -gt 0) { [void]$sb.Append('<w:tab/>') }
                [void]$sb.Append('<w:t xml:space="preserve">').Append((ConvertTo-XmlText $parts[$i])).Append('</w:t></w:r>')
            }
            [void]$sb.Append('</w:p>')
        }
    }
    # A4, margins as in Vietnamese administrative documents: 20 mm top/bottom/right, 30 mm left
    [void]$sb.Append('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/></w:sectPr>')
    [void]$sb.Append('</w:body></w:document>')

    $styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults>' +
        '<w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman" w:eastAsia="Times New Roman"/>' +
        '<w:sz w:val="28"/><w:szCs w:val="28"/><w:lang w:val="vi-VN"/></w:rPr></w:rPrDefault>' +
        '<w:pPrDefault><w:pPr><w:spacing w:before="60" w:after="60" w:line="288" w:lineRule="auto"/></w:pPr></w:pPrDefault>' +
        '</w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style></w:styles>'
    $contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
        '<Default Extension="xml" ContentType="application/xml"/>' +
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>'
    $rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'
    $docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>'

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $fs = [System.IO.File]::Open($Target, [System.IO.FileMode]::Create)
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $entries = [ordered]@{
            '[Content_Types].xml'          = $contentTypes
            '_rels/.rels'                  = $rels
            'word/document.xml'            = $sb.ToString()
            'word/styles.xml'              = $styles
            'word/_rels/document.xml.rels' = $docRels
        }
        foreach ($name in $entries.Keys) {
            $entry = $zip.CreateEntry($name)
            $es = $entry.Open()
            $bytes = $utf8.GetBytes($entries[$name])
            $es.Write($bytes, 0, $bytes.Length)
            $es.Dispose()
        }
    }
    finally { $zip.Dispose(); $fs.Dispose() }
}

function Write-Result {
    param($Data, [scriptblock]$Text)
    if ($Json) { $Data | ConvertTo-Json -Depth 6 } else { & $Text }
}

function Write-SetupState {
    param($State)
    if ($State.tesseract) { "Tesseract        : $($State.tesseract) ($($State.tesseractVersion))" } else { 'Tesseract        : NOT FOUND' }
    if ($State.languageDataFolder) { "Language '$Language'   : $($State.languageDataFolder)" } else { "Language '$Language'   : data NOT FOUND" }
    if ($State.ready) { 'READY.' } else { "NOT READY - missing: $($State.missing -join ', ')" }
}

# ---------------------------------------------------------------------------

switch ($Action) {

    'check' {
        # Read-only and fast: safe to run at the start of every use of the skill.
        $state = Get-SetupState
        Write-Result -Data $state -Text {
            Write-SetupState $state
            if (-not $state.ready) {
                '  Automatic (no administrator rights): scan2word.ps1 setup'
                "     downloads a portable Tesseract + language data into $($script:HomeDir)"
                '  Manual: the user runs   winget install --id UB-Mannheim.TesseractOCR -e'
                '     and afterwards       scan2word.ps1 setup   (fetches only the language data)'
            }
        }
        if (-not $state.ready) { exit 3 }
    }

    'setup' {
        # Installs only what is missing, so running it again on a machine that is
        # already set up changes nothing.
        $before = Get-SetupState
        $steps = @()
        if ($before.ready -and -not $Force) {
            $steps += 'Already set up - nothing to do.'
        }
        else {
            if (-not $before.tesseract -or $Force) {
                try {
                    Install-Bundle
                    $steps += "Installed portable Tesseract into $($script:EngineDir)"
                }
                catch {
                    $steps += "Portable Tesseract NOT installed: $($_.Exception.Message)"
                    $steps += 'Manual alternative - the user runs: winget install --id UB-Mannheim.TesseractOCR -e'
                }
            }
            if (-not (Test-Path -LiteralPath $script:DataDir)) { [void](New-Item -ItemType Directory -Path $script:DataDir -Force) }
            $haveData = Find-LanguageData (Find-Tesseract)
            foreach ($lang in ($Language -split '\+')) {
                $target = Join-Path $script:DataDir "$lang.traineddata"
                if ($haveData -and -not $Force) { continue }
                if ((Test-Path -LiteralPath $target) -and -not $Force) { continue }
                try {
                    Get-RemoteFile -Url "$($script:DataUrl)/$lang.traineddata" -Target $target
                    if ((Get-Item -LiteralPath $target).Length -lt 100KB) {
                        Remove-Item -LiteralPath $target -Force
                        throw "the file for '$lang' is unexpectedly small; is it a valid Tesseract language code?"
                    }
                    $steps += "Downloaded language data: $target"
                }
                catch { $steps += "Language data '$lang' NOT downloaded: $($_.Exception.Message)" }
            }
        }
        $state = Get-SetupState
        Write-Result -Data ([ordered]@{ steps = $steps; state = $state }) -Text {
            foreach ($s in $steps) { $s }
            Write-SetupState $state
        }
        if (-not $state.ready) { exit 3 }
    }

    'analyze' {
        $a = Get-Analysis (Resolve-InputFile)
        Write-Result -Data $a -Text {
            "File            : $($a.path)"
            "Type            : $($a.kind), $($a.pages) page(s), $($a.sizeKB) KB"
            if ($a.kind -eq 'pdf') { "Page size (mm)  : $($a.pageSizeMm)"; "Text ops / page : $($a.textOperatorsPerPage)" }
            "Verdict         : $($a.verdict)"
            "Needs OCR       : $($a.suggestedEngine -eq 'ocr')"
            "Note            : $($a.note)"
        }
    }

    'convert' {
        $full = Resolve-InputFile
        $a = Get-Analysis $full
        if (-not $OutFile) { $OutFile = [System.IO.Path]::ChangeExtension($full, '.docx') }
        $OutFile = [System.IO.Path]::GetFullPath($OutFile)
        if ((Test-Path -LiteralPath $OutFile) -and -not $Force) { throw "Output already exists: $OutFile (use -Force to overwrite, or -OutFile for another name)." }
        $outDir = [System.IO.Path]::GetDirectoryName($OutFile)
        if (-not (Test-Path -LiteralPath $outDir)) { [void](New-Item -ItemType Directory -Path $outDir -Force) }

        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        if ($a.verdict -eq 'text' -and -not $OcrTextPdf) {
            # Re-reading real text through OCR can only introduce mistakes, so stop
            # and let the caller decide instead of silently degrading the document.
            $summary = [ordered]@{ output = $null; skipped = $true; verdict = $a.verdict; note = $a.note }
            Write-Result -Data $summary -Text {
                'NOT CONVERTED: this PDF is not a scan.'
                $a.note
            }
            exit 4
        }
        else {
            $pageList = Invoke-Ocr -FullPath $full -Analysis $a
            Write-Docx -PageList $pageList -Target $OutFile
            $perPage = @($pageList | ForEach-Object {
                    [pscustomobject]@{ page = $_.number; characters = (($_.paragraphs | ForEach-Object { $_.text.Length }) | Measure-Object -Sum).Sum }
                })
            $total = ($perPage | Measure-Object characters -Sum).Sum
            $sparse = @($perPage | Where-Object { $_.characters -lt 80 } | ForEach-Object { $_.page })
            # Tesseract's own 0-100 confidence; below ~75 a page usually needs proofreading
            $meanConfidence = [Math]::Round((($pageList | Measure-Object confidence -Average).Average))
            $weak = @($pageList | Where-Object { $_.confidence -lt 75 } | ForEach-Object { $_.number })
            $textPath = $null
            if ($SaveText) {
                $textPath = [System.IO.Path]::ChangeExtension($OutFile, '.txt')
                $txt = New-Object System.Text.StringBuilder
                foreach ($pg in $pageList) {
                    [void]$txt.AppendLine("===== page $($pg.number) =====")
                    foreach ($p in $pg.paragraphs) { [void]$txt.AppendLine($p.text) }
                }
                [System.IO.File]::WriteAllText($textPath, $txt.ToString(), (New-Object System.Text.UTF8Encoding($false)))
            }
            $summary = [ordered]@{
                output = $OutFile; text = $textPath; engine = 'ocr'; language = $Language
                sourcePages = $a.pages; pagesConverted = $pageList.Count; characters = $total
                meanConfidence = $meanConfidence; lowConfidencePages = $weak
                nearlyEmptyPages = $sparse; seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 1)
            }
            Write-Result -Data $summary -Text {
                "Converted with Tesseract OCR (language: $Language). Mean confidence: $meanConfidence/100"
                if ($weak.Count -gt 0) { "Low-confidence pages (proofread against the original): $($weak -join ', ')" }
                "Output    : $OutFile"
                if ($textPath) { "Text copy : $textPath" }
                "Pages     : $($pageList.Count) of $($a.pages)   Characters: $total   Time: $($summary.seconds)s"
                if ($sparse.Count -gt 0) { "Nearly empty pages (check against the original): $($sparse -join ', ')" }
            }
        }
    }
}
