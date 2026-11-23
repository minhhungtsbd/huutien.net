$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BaseUrl = "https://huutien.net"
$Root = Split-Path -Parent $PSScriptRoot
$RawDir = Join-Path $Root "content\raw"
$HtmlDir = Join-Path $RawDir "html"
$MediaDir = Join-Path $Root "public\media"

New-Item -ItemType Directory -Force -Path $RawDir, $HtmlDir, $MediaDir | Out-Null

$Headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}

$ExcludedSlugs = @("sample-page", "privacy-policy")

function Fetch-Text([string]$Url) {
    try {
        $resp = Invoke-WebRequest -Uri $Url -Headers $Headers -UseBasicParsing -TimeoutSec 30
        return @{ Status = [int]$resp.StatusCode; Content = $resp.Content; Headers = $resp.Headers }
    } catch {
        $code = 0
        if ($_.Exception.Response) {
            try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        }
        return @{ Status = $code; Content = ""; Headers = @{} }
    }
}

function Fetch-JsonPaginated([string]$Endpoint) {
    $all = New-Object System.Collections.ArrayList
    $page = 1
    while ($true) {
        $sep = if ($Endpoint.Contains("?")) { "&" } else { "?" }
        $url = "$BaseUrl$Endpoint${sep}per_page=100&page=$page"
        $res = Fetch-Text $url
        if ($res.Status -ne 200 -or -not $res.Content) { break }
        $batch = $res.Content | ConvertFrom-Json
        if (-not $batch) { break }
        if ($batch -is [System.Array]) {
            foreach ($item in $batch) { [void]$all.Add($item) }
            $count = $batch.Count
        } else {
            [void]$all.Add($batch)
            $count = 1
        }
        $totalPages = 1
        if ($res.Headers["X-WP-TotalPages"]) {
            $totalPages = [int]$res.Headers["X-WP-TotalPages"]
        } elseif ($res.Headers["x-wp-totalpages"]) {
            $totalPages = [int]$res.Headers["x-wp-totalpages"]
        }
        Write-Host "  Fetched $Endpoint page $page/$totalPages ($count items)"
        if ($page -ge $totalPages -or $count -eq 0) { break }
        $page++
    }
    return $all
}

function Slug-ToFilename([string]$UrlPath) {
    $clean = $UrlPath.Trim("/")
    if (-not $clean) { return "home.html" }
    return ([regex]::Replace($clean, "[^a-zA-Z0-9_-]+", "__")) + ".html"
}

function Extract-UploadUrls([string]$Text) {
    $set = New-Object System.Collections.Generic.HashSet[string]
    if (-not $Text) { return $set }
    $matches = [regex]::Matches($Text, "https?://(?:www\.)?huutien\.net/wp-content/uploads/[^\s""'<>)\],\\]+", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $u = ($m.Value -split "\?")[0].TrimEnd(".", ",", ";", "\")
        if ($u -match "\.(jpg|jpeg|png|webp|gif|svg|ico|pdf)$") {
            [void]$set.Add($u)
        }
    }
    return $set
}

function Strip-WpSize([string]$Url) {
    return [regex]::Replace($Url, "-\d+x\d+(?=\.[a-zA-Z0-9]+$)", "")
}

Write-Host "1. Fetching WP REST API data..."
$pages = @(Fetch-JsonPaginated "/wp-json/wp/v2/pages" | Where-Object { $ExcludedSlugs -notcontains $_.slug })
$posts = @(Fetch-JsonPaginated "/wp-json/wp/v2/posts")
$categories = @(Fetch-JsonPaginated "/wp-json/wp/v2/categories")
$tags = @(Fetch-JsonPaginated "/wp-json/wp/v2/tags")
$media = @(Fetch-JsonPaginated "/wp-json/wp/v2/media")

[System.IO.File]::WriteAllText((Join-Path $RawDir "pages.json"), ($pages | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $RawDir "posts.json"), ($posts | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $RawDir "categories.json"), ($categories | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $RawDir "tags.json"), ($tags | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $RawDir "media.json"), ($media | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))

Write-Host "   Saved $($pages.Count) pages, $($posts.Count) posts, $($categories.Count) categories, $($tags.Count) tags, $($media.Count) media."

Write-Host "2. Discovering project URLs from sitemaps & /cong-trinh/..."
$urlsToFetch = New-Object System.Collections.Generic.HashSet[string]
[void]$urlsToFetch.Add("$BaseUrl/")
foreach ($p in $pages) { if ($p.link) { [void]$urlsToFetch.Add($p.link) } }
foreach ($p in $posts) { if ($p.link) { [void]$urlsToFetch.Add($p.link) } }
foreach ($c in $categories) { if ($c.link) { [void]$urlsToFetch.Add($c.link) } }

$projectUrls = New-Object System.Collections.Generic.HashSet[string]
foreach ($sm in @("/sitemap_index.xml", "/featured_item-sitemap.xml", "/wp-sitemap.xml", "/cong-trinh/", "/featured_item/")) {
    $res = Fetch-Text "$BaseUrl$sm"
    if ($res.Status -eq 200 -and $res.Content) {
        foreach ($m in [regex]::Matches($res.Content, "https?://(?:www\.)?huutien\.net/du-an/[^\s""'<>]+")) {
            [void]$projectUrls.Add($m.Value.TrimEnd("/") + "/")
        }
        foreach ($m in [regex]::Matches($res.Content, "https?://(?:www\.)?huutien\.net/[^\s""'<>]*sitemap[^\s""'<>]*\.xml")) {
            if ($m.Value -match "featured_item|du-an") {
                $r2 = Fetch-Text $m.Value
                if ($r2.Status -eq 200 -and $r2.Content) {
                    foreach ($m2 in [regex]::Matches($r2.Content, "https?://(?:www\.)?huutien\.net/du-an/[^\s""'<>]+")) {
                        [void]$projectUrls.Add($m2.Value.TrimEnd("/") + "/")
                    }
                }
            }
        }
    }
}

Write-Host "   Found $($projectUrls.Count) project URLs."
foreach ($pu in $projectUrls) { [void]$urlsToFetch.Add($pu) }
[System.IO.File]::WriteAllText((Join-Path $RawDir "project_urls.json"), (@($projectUrls | Sort-Object) | ConvertTo-Json -Depth 4), [System.Text.UTF8Encoding]::new($false))

Write-Host "3. Fetching $($urlsToFetch.Count) rendered HTML pages..."
$htmlIndex = @{}
$allUploadUrls = New-Object System.Collections.Generic.HashSet[string]

foreach ($m in $media) {
    if ($m.source_url) { [void]$allUploadUrls.Add($m.source_url) }
}

foreach ($u in ($urlsToFetch | Sort-Object)) {
    $uri = [Uri]$u
    $path = $uri.AbsolutePath
    if (-not $path) { $path = "/" }
    $fname = Slug-ToFilename $path
    $res = Fetch-Text $u
    if ($res.Status -eq 200 -and $res.Content) {
        [System.IO.File]::WriteAllText((Join-Path $HtmlDir $fname), $res.Content, [System.Text.UTF8Encoding]::new($false))
        $htmlIndex[$path] = @{
            url = $u
            file = $fname
            status = 200
            is_project = $path.StartsWith("/du-an/")
        }
        foreach ($img in (Extract-UploadUrls $res.Content)) {
            [void]$allUploadUrls.Add($img)
        }
        Write-Host "  [200] $path"
    } else {
        $htmlIndex[$path] = @{ url = $u; file = $null; status = $res.Status }
        Write-Host "  [$($res.Status)] $path"
    }
}

[System.IO.File]::WriteAllText((Join-Path $RawDir "html_index.json"), ($htmlIndex | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))

foreach ($jf in @("pages.json", "posts.json")) {
    $txt = [System.IO.File]::ReadAllText((Join-Path $RawDir $jf))
    foreach ($img in (Extract-UploadUrls $txt)) { [void]$allUploadUrls.Add($img) }
}

$originals = New-Object System.Collections.Generic.HashSet[string]
foreach ($u in $allUploadUrls) {
    [void]$originals.Add((Strip-WpSize $u))
}

Write-Host "4. Downloading $($originals.Count) unique original media files (from $($allUploadUrls.Count) refs)..."
$downloaded = @{}
$failed = New-Object System.Collections.ArrayList

function Download-One([string]$Url) {
    $uri = [Uri]$Url
    $decodedPath = [Uri]::UnescapeDataString($uri.AbsolutePath)
    $rel = ($decodedPath -replace "^/wp-content/uploads/", "").TrimStart("/")
    if (-not $rel) { return @{ Ok = $false; Status = 0; Rel = "" } }
    $dest = Join-Path $MediaDir ($rel -replace "/", "\")
    if ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 0)) {
        return @{ Ok = $true; Status = 200; Rel = $rel }
    }
    $destDir = Split-Path -Parent $dest
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    try {
        Invoke-WebRequest -Uri $Url -Headers $Headers -OutFile $dest -UseBasicParsing -TimeoutSec 30
        if ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 0)) {
            return @{ Ok = $true; Status = 200; Rel = $rel }
        }
        return @{ Ok = $false; Status = 0; Rel = $rel }
    } catch {
        $code = 0
        if ($_.Exception.Response) {
            try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        }
        if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
        return @{ Ok = $false; Status = $code; Rel = $rel }
    }
}

$i = 0
$total = $originals.Count
foreach ($u in ($originals | Sort-Object)) {
    $i++
    $r = Download-One $u
    if ($r.Ok) {
        $downloaded[$u] = "/media/$($r.Rel)"
    } else {
        [void]$failed.Add(@{ url = $u; status = $r.Status })
    }
    if ($i % 25 -eq 0 -or $i -eq $total) {
        Write-Host "   Progress: $i/$total downloaded=$($downloaded.Count) failed=$($failed.Count)"
    }
}

# Fallback for resized images whose original was not found
$fallbacks = @($allUploadUrls | Where-Object { -not $downloaded.ContainsKey((Strip-WpSize $_)) } | Sort-Object)
if ($fallbacks.Count -gt 0) {
    Write-Host "   Downloading $($fallbacks.Count) fallback resized images..."
    foreach ($u in $fallbacks) {
        $r = Download-One $u
        if ($r.Ok) {
            $downloaded[$u] = "/media/$($r.Rel)"
        }
    }
}

$manifest = @{ downloaded = $downloaded; failed = $failed }
[System.IO.File]::WriteAllText((Join-Path $RawDir "media_manifest.json"), ($manifest | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
Write-Host "DONE! Downloaded $($downloaded.Count) media files, $($failed.Count) failed."
