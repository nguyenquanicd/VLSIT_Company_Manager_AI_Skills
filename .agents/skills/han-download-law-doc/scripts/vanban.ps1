<#
.SYNOPSIS
    Search and download official Vietnamese legal documents (original PDF/DOC files)
    from the Government portal https://vanban.chinhphu.vn.

.DESCRIPTION
    Three actions:
      search    - find documents by keyword or document number (so hieu)
      info      - show the metadata and attachment links of one document
      download  - save the original attached files plus a metadata.json

    This file is intentionally ASCII-only so that Windows PowerShell 5.1 parses it
    the same way regardless of the system code page. Vietnamese text only ever
    arrives through parameters or from the website.

.EXAMPLE
    .\vanban.ps1 search -Keyword "59/2020/QH14"
    .\vanban.ps1 search -Keyword "bao ve du lieu ca nhan" -Loai nghidinh -Year 2023 -Top 20
    .\vanban.ps1 info -DocId 216536
    .\vanban.ps1 download -SoHieu "59/2020/QH14;13/2023/ND-CP" -OutDir .\van-ban
    .\vanban.ps1 download -DocId 216536,216510
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('search', 'info', 'related', 'download')]
    [string]$Action,

    # search: free text or a document number
    [string]$Keyword,

    # download: one or more document numbers, separated by ';' (or passed as an array)
    [string[]]$SoHieu,

    # info / download: numeric ids taken from search results
    [string[]]$DocId,

    # search filters
    [ValidateSet('', 'hienphap', 'sacluat', 'luat', 'nghidinh', 'quyetdinh', 'thongtu')]
    [string]$Loai = '',
    [int]$Year = 0,
    [int]$Top = 20,

    # oldest year to look at when a broad query has to be split by year;
    # 0 = default (1990 for search, the base document's year minus one for related)
    [int]$FromYear = 0,

    # 1 = van ban quy pham phap luat (default), 2 = van ban chi dao dieu hanh
    [int]$Class = 1,

    [string]$OutDir = '.\van-ban',
    [switch]$Force,
    [switch]$Json,

    # pause between requests, to stay polite to a public government server
    [int]$DelayMs = 800
)

$ErrorActionPreference = 'Stop'
$BaseUrl = 'https://vanban.chinhphu.vn'
$TypeGroup = @{ hienphap = 1; sacluat = 2; luat = 3; nghidinh = 4; quyetdinh = 5; thongtu = 6 }

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.Web

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.CookieContainer = New-Object System.Net.CookieContainer
$handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(120)
[void]$client.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) vanban-skill/1.0 PowerShell')
[void]$client.DefaultRequestHeaders.TryAddWithoutValidation('Accept-Language', 'vi-VN,vi;q=0.9')

$script:lastRequest = [DateTime]::MinValue

function Wait-Polite {
    $elapsed = ([DateTime]::Now - $script:lastRequest).TotalMilliseconds
    if ($elapsed -lt $DelayMs) { Start-Sleep -Milliseconds ([int]($DelayMs - $elapsed)) }
    $script:lastRequest = [DateTime]::Now
}

function Invoke-Http {
    # Returns the response; retries a couple of times on transient failures.
    param([string]$Url, [string]$Body)
    $lastError = $null
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        Wait-Polite
        try {
            if ($PSBoundParameters.ContainsKey('Body')) {
                $content = New-Object System.Net.Http.StringContent($Body, [System.Text.Encoding]::UTF8, 'application/x-www-form-urlencoded')
                $resp = $client.PostAsync($Url, $content).GetAwaiter().GetResult()
            }
            else {
                $resp = $client.GetAsync($Url).GetAwaiter().GetResult()
            }
            if ($resp.IsSuccessStatusCode) { return $resp }
            $lastError = "HTTP $([int]$resp.StatusCode) $($resp.ReasonPhrase)"
            # 4xx will not get better by retrying
            if ([int]$resp.StatusCode -lt 500) { break }
        }
        catch {
            $lastError = $_.Exception.GetBaseException().Message
        }
        Start-Sleep -Seconds (2 * $attempt)
    }
    throw "Request failed for $Url : $lastError"
}

function Get-Html {
    param([string]$Url, [string]$Body)
    if ($PSBoundParameters.ContainsKey('Body')) { $resp = Invoke-Http -Url $Url -Body $Body }
    else { $resp = Invoke-Http -Url $Url }
    $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function ConvertTo-UrlEncoded {
    # [uri]::EscapeDataString rejects strings above ~65k chars on .NET Framework,
    # and __VIEWSTATE is far larger than that, so encode in chunks.
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $Text.Length; $i += 20000) {
        $len = [Math]::Min(20000, $Text.Length - $i)
        [void]$sb.Append([uri]::EscapeDataString($Text.Substring($i, $len)))
    }
    return $sb.ToString()
}

function ConvertFrom-HtmlText {
    param([string]$Html)
    if ($null -eq $Html) { return '' }
    $t = [regex]::Replace($Html, '<[^>]+>', ' ')
    $t = [System.Web.HttpUtility]::HtmlDecode($t)
    return ([regex]::Replace($t, '\s+', ' ')).Trim()
}

function Get-NormalizedCode {
    # Document numbers on the site are typed by hand: some use Cyrillic look-alike
    # letters, stray spaces, or D-with-stroke. Fold all of that away so that
    # "13/2023/ND-CP" still matches what the site stores.
    param([string]$Code)
    if ($null -eq $Code) { return '' }
    $c = $Code.ToUpperInvariant()
    $c = $c.Replace([string][char]0x0110, 'D')   # D with stroke
    $c = $c.Replace([string][char]0x0421, 'C').Replace([string][char]0x0420, 'P')   # Cyrillic ES, ER
    $c = $c.Replace([string][char]0x041D, 'H').Replace([string][char]0x0422, 'T')   # Cyrillic EN, TE
    $c = $c.Replace([string][char]0x2013, '-').Replace([string][char]0x2014, '-')
    return [regex]::Replace($c, '\s+', '')
}

function Get-SafeName {
    param([string]$Name)
    $n = $Name
    foreach ($ch in [System.IO.Path]::GetInvalidFileNameChars()) { $n = $n.Replace([string]$ch, '_') }
    $n = $n.Trim().TrimEnd('.')
    if ([string]::IsNullOrWhiteSpace($n)) { $n = 'van-ban' }
    return $n
}

function Get-ListUrl {
    param([string]$Type = '')
    $q = "classid=$Class&mode=1"
    if ($Type) { $q += "&typegroupid=$($TypeGroup[$Type])" }
    return "$BaseUrl/he-thong-van-ban?$q"
}

function ConvertFrom-ResultPage {
    param([string]$Html)
    $results = @()
    foreach ($chunk in ($Html -split '<tr[\s>]')) {
        if ($chunk -notmatch 'class="code"') { continue }
        $id = [regex]::Match($chunk, 'docid=(\d+)').Groups[1].Value
        if (-not $id) { continue }
        $files = @()
        foreach ($m in [regex]::Matches($chunk, 'class="bl-doc-file">\s*<a[^>]*href="([^"]+)"')) {
            $files += [System.Web.HttpUtility]::HtmlDecode($m.Groups[1].Value)
        }
        $results += [pscustomobject][ordered]@{
            docId      = $id
            soHieu     = ConvertFrom-HtmlText ([regex]::Match($chunk, 'class="code">(.*?)</span>', 'Singleline').Groups[1].Value)
            ngayBanHanh = ConvertFrom-HtmlText ([regex]::Match($chunk, 'class="issued-date">(.*?)</span>', 'Singleline').Groups[1].Value)
            trichYeu   = ConvertFrom-HtmlText ([regex]::Match($chunk, 'class="substract">(.*?)</span>', 'Singleline').Groups[1].Value)
            url        = "$BaseUrl/?pageid=27160&docid=$id"
            files      = $files
        }
    }
    return , $results
}

# The portal's keyword search returns at most 50 rows - the footer of the result
# grid reads "1 - 50 | 50" - and offers no pager, so a query that matches more
# documents is silently cut to the 50 newest. Search-One runs one such query.
# Search-Documents works around the cap by splitting a broad query by year (and,
# for a year that is itself full, by document type), and sets $script:SearchCapped
# when it still could not see everything.
$script:SearchCapped = $false
$script:FormPages = @{}
$script:ResultCap = 50

function Search-One {
    param([string]$Text, [int]$YearFilter, [string]$TypeFilter)

    $listUrl = Get-ListUrl -Type $TypeFilter

    # The portal intermittently answers a valid query with an empty grid (HTTP 200,
    # roughly one request in five in testing). Posting the same form again usually
    # returns the rows, but not always, so every retry starts from a fresh copy of
    # the search form. A genuine "no result" stays empty through all attempts.
    $rows = @()
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        # one GET per list URL is enough while results come back: the form it
        # returns can be posted repeatedly
        if ($attempt -gt 1) { $script:FormPages.Remove($listUrl) }
        if (-not $script:FormPages.ContainsKey($listUrl)) { $script:FormPages[$listUrl] = Get-Html -Url $listUrl }
        $page = $script:FormPages[$listUrl]

        # The search box belongs to an ASP.NET control whose id prefix can change when
        # the portal is redeployed, so discover it instead of hard-coding it.
        $m = [regex]::Match($page, 'name="(ctrl_\d+_\d+)\$txtSearchKeyword"')
        if (-not $m.Success) { throw 'Search form not found on vanban.chinhphu.vn - the page layout may have changed.' }
        $prefix = $m.Groups[1].Value

        $fields = [ordered]@{}
        foreach ($im in [regex]::Matches($page, '<input[^>]*type="hidden"[^>]*>')) {
            $name = [regex]::Match($im.Value, 'name="([^"]*)"').Groups[1].Value
            if (-not $name) { continue }
            $fields[$name] = [System.Web.HttpUtility]::HtmlDecode([regex]::Match($im.Value, 'value="([^"]*)"').Groups[1].Value)
        }
        $fields['__EVENTTARGET'] = ''
        $fields['__EVENTARGUMENT'] = ''
        $fields["$prefix`$txtSearchKeyword"] = $Text
        $fields["$prefix`$drdDocCategory"] = '0'
        $fields["$prefix`$drdDocOrg"] = '0'
        $fields["$prefix`$drdDocYear"] = [string]$YearFilter
        $fields["$prefix`$drdRecordPerPage"] = '50'
        # value of the submit button, "Tim kiem" with Vietnamese diacritics
        $fields["$prefix`$btnSearch"] = [System.Web.HttpUtility]::UrlDecode('T%C3%ACm%20ki%E1%BA%BFm')

        $pairs = foreach ($k in $fields.Keys) { (ConvertTo-UrlEncoded $k) + '=' + (ConvertTo-UrlEncoded $fields[$k]) }
        $rows = ConvertFrom-ResultPage (Get-Html -Url $listUrl -Body ($pairs -join '&'))
        if ($rows.Count -gt 0) { break }
        Start-Sleep -Milliseconds 700
    }
    return , $rows
}

function Search-Documents {
    param([string]$Text, [int]$Limit, [int]$StopYear = 1990)

    $script:SearchCapped = $false
    $rows = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $merge = {
        param($list)
        foreach ($r in $list) { if (-not $seen.ContainsKey($r.docId)) { $seen[$r.docId] = $true; $rows.Add($r) } }
    }

    $first = Search-One -Text $Text -YearFilter $Year -TypeFilter $Loai
    & $merge $first
    $full = ($first.Count -ge $script:ResultCap)

    if ($full -and $Limit -gt $script:ResultCap) {
        if ($Year -ne 0) {
            # the caller fixed one year; there is nothing finer to split by except type
            $script:SearchCapped = $true
        }
        else {
            # split by year, newest first, until enough rows have been collected
            $rows.Clear(); $seen.Clear()
            for ($y = (Get-Date).Year; $y -ge $StopYear -and $rows.Count -lt $Limit; $y--) {
                $inYear = Search-One -Text $Text -YearFilter $y -TypeFilter $Loai
                if ($inYear.Count -ge $script:ResultCap) {
                    if ($Class -eq 1 -and -not $Loai) {
                        # a full year: split it by document type as well
                        $byType = @($inYear)
                        foreach ($t in $TypeGroup.Keys) {
                            $part = Search-One -Text $Text -YearFilter $y -TypeFilter $t
                            if ($part.Count -ge $script:ResultCap) { $script:SearchCapped = $true }
                            $byType += $part
                        }
                        $inYear = $byType
                    }
                    else { $script:SearchCapped = $true }
                }
                & $merge ($inYear | Sort-Object { ConvertTo-Date $_.ngayBanHanh } -Descending)
            }
        }
    }

    $all = $rows.ToArray()
    if ($all.Count -gt $Limit) { $all = $all[0..($Limit - 1)] }
    return , $all
}

function Get-DocumentInfo {
    param([string]$Id)
    if ($Id -notmatch '^\d+$') { throw "DocId must be a number, got '$Id'." }
    $url = "$BaseUrl/?pageid=27160&docid=$Id"

    # The portal sometimes answers a valid id with the page "Khong tim thay van ban
    # nay" (document not found) and keeps answering that for the same address for
    # tens of seconds, apparently from a cache. The address the search grid links
    # to carries a classid parameter and is not affected, so rotate through the
    # address forms and only believe "not found" after all of them failed twice.
    $notFoundText = 'Kh' + [char]0x00F4 + 'ng t' + [char]0x00EC + 'm th' + [char]0x1EA5 + 'y v' + [char]0x0103 + 'n b' + [char]0x1EA3 + 'n n' + [char]0x00E0 + 'y'
    $forms = @("$url&classid=1", "$url&classid=2", $url)
    $tries = 6
    for ($attempt = 0; $attempt -lt $tries; $attempt++) {
        $html = Get-Html -Url $forms[$attempt % $forms.Count]
        $title = ConvertFrom-HtmlText ([regex]::Match($html, '<h4 class="title">(.*?)</h4>', 'Singleline').Groups[1].Value)
        if ($title -and $title -notlike "*$notFoundText*") { break }
        Start-Sleep -Milliseconds 700
    }
    if (-not $title -or $title -like "*$notFoundText*") { throw "No document found for docid $Id (the portal answered 'not found' for $tries requests)." }

    $meta = [ordered]@{}
    $rows = [regex]::Matches($html, '<td class="col1"[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>', 'Singleline')
    foreach ($r in $rows) {
        $label = ConvertFrom-HtmlText $r.Groups[1].Value
        if ($r.Groups[2].Value -match 'view-file') { continue }   # the attachment row is reported separately
        if ($label) { $meta[$label] = ConvertFrom-HtmlText $r.Groups[2].Value }
    }
    $files = @()
    foreach ($m in [regex]::Matches($html, '<a[^>]*href="([^"]+)"[^>]*class="view-file"')) {
        $files += [System.Web.HttpUtility]::HtmlDecode($m.Groups[1].Value)
    }
    if (-not $title -and $meta.Count -eq 0) { throw "No document found for docid $Id." }

    # "So ky hieu" is always the first metadata row on the detail page.
    $code = ''
    if ($meta.Count -gt 0) { $code = @($meta.Values)[0] }

    # The issue date is the second metadata row. The effective-date row is
    # optional and carries its own id, so read it by that id, not by position.
    $issued = ''
    if ($meta.Count -gt 1) { $issued = @($meta.Values)[1] }
    $effective = [regex]::Match($html, 'tr_ngaycohieuluc"[^>]*>\s*<td[^>]*>.*?</td>\s*<td[^>]*>\s*(\d[\d\-/]+)', 'Singleline').Groups[1].Value
    $effectiveDate = ConvertTo-Date $effective
    $notYetInForce = [bool]($effectiveDate -and $effectiveDate -gt (Get-Date).Date)

    return [pscustomobject][ordered]@{
        docId         = $Id
        soHieu        = $code
        tieuDe        = $title
        ngayBanHanh   = $issued
        ngayHieuLuc   = $effective
        chuaCoHieuLuc = $notYetInForce
        url           = $url
        thongTin      = $meta
        files         = @($files | Select-Object -Unique)
    }
}

function ConvertTo-Date {
    # The portal writes dates as dd/MM/yyyy in lists and dd-MM-yyyy on detail pages.
    param([string]$Text)
    if ($Text -match '^\s*(\d{1,2})[-/](\d{1,2})[-/](\d{4})') {
        try { return New-Object DateTime([int]$Matches[3], [int]$Matches[2], [int]$Matches[1]) } catch { }
    }
    return $null
}

function Resolve-DocumentCode {
    # Turns a document number into portal ids. Only an exact (normalized) match
    # counts: handing someone the wrong law is worse than handing none.
    param([string]$Code)
    $want = Get-NormalizedCode $Code
    $hits = Search-Documents -Text $Code -Limit 50
    $exact = @($hits | Where-Object { (Get-NormalizedCode $_.soHieu) -eq $want })
    # The portal matches text literally, so "ND-CP" typed without the Vietnamese
    # D finds nothing. Retry on the "number/year" part alone and let the
    # normalized comparison pick the right row.
    $numberPart = [regex]::Match($Code, '^\s*\d+[^/]*/\d{4}').Value.Trim()
    if ($exact.Count -eq 0 -and $numberPart -and $numberPart -ne $Code.Trim()) {
        $hits = Search-Documents -Text $numberPart -Limit 200
        $exact = @($hits | Where-Object { (Get-NormalizedCode $_.soHieu) -eq $want })
    }
    return [pscustomobject]@{
        ids        = @($exact | ForEach-Object { $_.docId })
        candidates = @($hits | Select-Object -First 5 | ForEach-Object { "[$($_.docId)] $($_.soHieu) - $($_.trichYeu)" })
    }
}

function Save-Document {
    param($Info)

    $folderName = Get-SafeName ($Info.soHieu -replace '[\\/]', '_')
    if ($folderName -eq 'van-ban') { $folderName = "docid_$($Info.docId)" }
    $folder = Join-Path $OutDir $folderName
    if (-not (Test-Path -LiteralPath $folder)) { [void](New-Item -ItemType Directory -Path $folder -Force) }
    $folder = (Resolve-Path -LiteralPath $folder).Path

    $saved = @()
    $problems = @()
    foreach ($fileUrl in $Info.files) {
        $uri = $null
        if (-not [uri]::TryCreate($fileUrl, [System.UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne 'https' -or $uri.Host -notmatch '(^|\.)chinhphu\.vn$') {
            # only ever fetch attachments hosted by the Government portal itself
            $problems += "Skipped (not a chinhphu.vn https link): $fileUrl"
            continue
        }
        $name = Get-SafeName ([uri]::UnescapeDataString([System.IO.Path]::GetFileName($uri.AbsolutePath)))
        $target = Join-Path $folder $name
        if ((Test-Path -LiteralPath $target) -and -not $Force) {
            $saved += [pscustomobject][ordered]@{ path = $target; bytes = (Get-Item -LiteralPath $target).Length; status = 'already-exists'; source = $fileUrl }
            continue
        }
        try {
            $resp = Invoke-Http -Url $fileUrl
            $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
            $status = 'downloaded'
            if ($name -match '\.pdf$') {
                $head = [System.Text.Encoding]::ASCII.GetString($bytes, 0, [Math]::Min(5, $bytes.Length))
                if ($head -ne '%PDF-') { $status = 'downloaded-but-not-a-valid-pdf' }
            }
            [System.IO.File]::WriteAllBytes($target, $bytes)
            $saved += [pscustomobject][ordered]@{ path = $target; bytes = $bytes.Length; status = $status; source = $fileUrl }
        }
        catch {
            $problems += "Failed: $fileUrl - $($_.Exception.Message)"
        }
    }
    if ($Info.files.Count -eq 0) { $problems += 'The portal lists no attached file for this document.' }

    $record = [ordered]@{
        docId     = $Info.docId
        soHieu    = $Info.soHieu
        tieuDe    = $Info.tieuDe
        nguon     = $Info.url
        ngayBanHanh   = $Info.ngayBanHanh
        ngayHieuLuc   = $Info.ngayHieuLuc
        chuaCoHieuLuc = $Info.chuaCoHieuLuc
        thongTin  = $Info.thongTin
        tepDinhKem = @($saved | ForEach-Object { [ordered]@{ tep = [System.IO.Path]::GetFileName($_.path); nguon = $_.source; bytes = $_.bytes } })
        taiLuc    = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
    }
    $metaPath = Join-Path $folder 'metadata.json'
    [System.IO.File]::WriteAllText($metaPath, ($record | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))

    return [pscustomobject][ordered]@{
        docId    = $Info.docId
        soHieu   = $Info.soHieu
        tieuDe   = $Info.tieuDe
        ngayBanHanh   = $Info.ngayBanHanh
        ngayHieuLuc   = $Info.ngayHieuLuc
        chuaCoHieuLuc = $Info.chuaCoHieuLuc
        folder   = $folder
        files    = $saved
        problems = $problems
        ok       = ($saved.Count -gt 0)
    }
}

function Split-List {
    param([string[]]$Values)
    $out = @()
    foreach ($v in $Values) { foreach ($p in ($v -split '[;,]')) { if ($p.Trim()) { $out += $p.Trim() } } }
    return , $out
}

function Write-Result {
    param($Data, [scriptblock]$Text)
    if ($Json) { $Data | ConvertTo-Json -Depth 8 }
    else { & $Text }
}

# ---------------------------------------------------------------------------

switch ($Action) {

    'search' {
        if (-not $Keyword) { throw 'search needs -Keyword.' }
        $stopYear = 1990
        if ($FromYear -gt 0) { $stopYear = $FromYear }
        $found = Search-Documents -Text $Keyword -Limit $Top -StopYear $stopYear
        $capped = $script:SearchCapped
        Write-Result -Data ([ordered]@{ keyword = $Keyword; count = $found.Count; incomplete = $capped; results = $found }) -Text {
            if ($found.Count -eq 0) { "No result for '$Keyword' on vanban.chinhphu.vn."; return }
            "$($found.Count) result(s) for '$Keyword':"
            foreach ($r in $found) {
                "[$($r.docId)] $($r.soHieu) | $($r.ngayBanHanh) | $($r.trichYeu) | files: $($r.files.Count)"
            }
            if ($capped) { 'NOTE: the portal cuts a query at 50 rows; at least one year or type still hit that limit, so the list may be incomplete. Narrow the keyword or add -Loai / -Year.' }
        }
    }

    'info' {
        $ids = Split-List $DocId
        if ($ids.Count -eq 0) { throw 'info needs -DocId.' }
        $infos = @(foreach ($id in $ids) { Get-DocumentInfo -Id $id })
        Write-Result -Data $infos -Text {
            foreach ($i in $infos) {
                "== [$($i.docId)] $($i.tieuDe)"
                foreach ($k in $i.thongTin.Keys) { "   ${k}: $($i.thongTin[$k])" }
                foreach ($f in $i.files) { "   file: $f" }
                "   url: $($i.url)"
            }
        }
    }

    'related' {
        # Lists every document on the portal that mentions the base document by
        # number or by name: amendments, implementing decrees and circulars,
        # earlier and later versions. It only gathers candidates; deciding how
        # each one relates to the base document is left to the reader, because
        # that judgement needs the wording of the titles, not a pattern match.
        $ids = Split-List $DocId
        foreach ($code in (Split-List $SoHieu)) { $ids += (Resolve-DocumentCode $code).ids }
        $ids = @($ids | Select-Object -Unique)
        if ($ids.Count -ne 1) { throw "related needs exactly one base document (-DocId or -SoHieu); got $($ids.Count)." }

        $base = Get-DocumentInfo -Id $ids[0]
        $baseDate = ConvertTo-Date $base.ngayBanHanh
        $name = $base.tieuDe
        if ($name -match ':\s*(.+)$') { $name = $Matches[1].Trim() }
        $terms = @($base.soHieu, $name)
        if ($Keyword) { $terms += ($Keyword -split ';' | ForEach-Object { $_.Trim() }) }
        # the portal's search box accepts at most 100 characters
        $terms = @($terms | Where-Object { $_ } | ForEach-Object { if ($_.Length -gt 100) { $_.Substring(0, 100) } else { $_ } } | Select-Object -Unique)

        $Loai = ''; $Year = 0
        $limit = [Math]::Max($Top, 200)
        # look back to a year before the base document: older documents belong to
        # the previous version of the law and are rarely wanted
        $stopYear = 1990
        if ($FromYear -gt 0) { $stopYear = $FromYear } elseif ($baseDate) { $stopYear = $baseDate.Year - 1 }
        $incomplete = $false
        $found = [ordered]@{}
        foreach ($c in 1, 2) {
            $Class = $c
            foreach ($term in $terms) {
                $hitsForTerm = Search-Documents -Text $term -Limit $limit -StopYear $stopYear
                if ($script:SearchCapped) { $incomplete = $true }
                foreach ($hit in $hitsForTerm) {
                    if ($hit.docId -eq $base.docId) { continue }
                    if ($found.Contains($hit.docId)) {
                        if ($found[$hit.docId].timThayBang -notcontains $term) { $found[$hit.docId].timThayBang += $term }
                        continue
                    }
                    $hitDate = ConvertTo-Date $hit.ngayBanHanh
                    $after = $null
                    if ($hitDate -and $baseDate) { $after = ($hitDate -ge $baseDate) }
                    $found[$hit.docId] = [pscustomobject][ordered]@{
                        docId        = $hit.docId
                        soHieu       = $hit.soHieu
                        ngayBanHanh  = $hit.ngayBanHanh
                        banHanhSauVanBanGoc = $after
                        lop          = $c
                        trichYeu     = $hit.trichYeu
                        timThayBang  = @($term)
                        soFile       = $hit.files.Count
                        url          = $hit.url
                        sortKey      = $hitDate
                    }
                }
            }
        }
        $list = @($found.Values | Sort-Object sortKey -Descending | Select-Object * -ExcludeProperty sortKey)
        Write-Result -Data ([ordered]@{ base = $base; searchTerms = $terms; searchedFromYear = $stopYear; incomplete = $incomplete; count = $list.Count; candidates = $list }) -Text {
            $line = "BASE [$($base.docId)] $($base.soHieu) | issued $($base.ngayBanHanh) | in force from $($base.ngayHieuLuc)"
            if ($base.chuaCoHieuLuc) { $line += '  ** NOT YET IN FORCE **' }
            $line
            "     $($base.tieuDe)"
            "Search terms: $($terms -join ' ; ')   (documents issued from $stopYear onward)"
            if ($incomplete) { 'NOTE: the portal cuts a query at 50 rows; for at least one term a year or type still hit that limit, so the list may be incomplete. Re-run with narrower -Keyword phrases.' }
            "$($list.Count) candidate(s), newest first. AFTER/BEFORE = issued after or before the base document; C1 = legal normative, C2 = directive."
            foreach ($r in $list) {
                $when = '?'
                if ($r.banHanhSauVanBanGoc -eq $true) { $when = 'AFTER' } elseif ($r.banHanhSauVanBanGoc -eq $false) { $when = 'BEFORE' }
                "[$($r.docId)] $($r.soHieu) | $($r.ngayBanHanh) | $when | C$($r.lop) | $($r.trichYeu)"
            }
        }
    }

    'download' {
        $ids = Split-List $DocId
        $notFound = @()
        foreach ($code in (Split-List $SoHieu)) {
            $resolved = Resolve-DocumentCode $code
            if ($resolved.ids.Count -eq 0) {
                $notFound += [pscustomobject][ordered]@{ soHieu = $code; candidates = $resolved.candidates }
                continue
            }
            $ids += $resolved.ids
        }
        $ids = @($ids | Select-Object -Unique)
        if ($ids.Count -eq 0 -and $notFound.Count -eq 0) { throw 'download needs -SoHieu or -DocId.' }

        $done = @(foreach ($id in $ids) { Save-Document -Info (Get-DocumentInfo -Id $id) })
        Write-Result -Data @{ downloaded = $done; notFound = $notFound } -Text {
            foreach ($d in $done) {
                "== [$($d.docId)] $($d.soHieu) - $($d.tieuDe)"
                $force = "   issued: $($d.ngayBanHanh) | in force from: $($d.ngayHieuLuc)"
                if (-not $d.ngayHieuLuc) { $force = "   issued: $($d.ngayBanHanh) | in force from: (not stated on the portal)" }
                if ($d.chuaCoHieuLuc) { $force += '  ** NOT YET IN FORCE **' }
                $force
                "   folder: $($d.folder)"
                foreach ($f in $d.files) { "   $($f.status): $([System.IO.Path]::GetFileName($f.path)) ($([Math]::Round($f.bytes / 1KB)) KB)" }
                foreach ($p in $d.problems) { "   ! $p" }
            }
            foreach ($n in $notFound) {
                "== NOT FOUND: $($n.soHieu)"
                if ($n.candidates.Count -gt 0) { '   closest results on the portal:'; foreach ($c in $n.candidates) { "     $c" } }
            }
        }
        if (@($done | Where-Object { -not $_.ok }).Count -gt 0 -or $notFound.Count -gt 0) { exit 2 }
    }
}
