$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$RawDir = Join-Path $Root "content\raw"
$HtmlDir = Join-Path $RawDir "html"
$MediaDir = Join-Path $Root "public\media"
$OutPath = Join-Path $Root "content\data.json"

$pagesRaw = Get-Content (Join-Path $RawDir "pages.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$postsRaw = Get-Content (Join-Path $RawDir "posts.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$catsRaw  = Get-Content (Join-Path $RawDir "categories.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$mediaRaw = Get-Content (Join-Path $RawDir "media.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# Map media ID -> local path
$mediaById = @{}
foreach ($m in $mediaRaw) {
    if ($m.id -and $m.source_url) {
        $mediaById[[string]$m.id] = $m.source_url
    }
}

function Decode-Html([string]$Text) {
    if (-not $Text) { return "" }
    return [System.Net.WebUtility]::HtmlDecode($Text)
}

function Resolve-LocalMedia([string]$Url) {
    if (-not $Url) { return "" }
    $clean = ($Url -split "\?")[0].Trim()
    if ($clean -notmatch "huutien\.net/wp-content/uploads/") {
        if ($clean.StartsWith("/media/")) { return $clean }
        return ""
    }
    try {
        $uri = [Uri]$clean
        $decodedPath = [Uri]::UnescapeDataString($uri.AbsolutePath)
    } catch {
        return ""
    }
    $rel = ($decodedPath -replace "^/wp-content/uploads/", "").TrimStart("/")
    # Try original (without -WxH) first
    $relOrig = [regex]::Replace($rel, "-\d+x\d+(?=\.[a-zA-Z0-9]+$)", "")
    $pOrig = Join-Path $MediaDir ($relOrig -replace "/", "\")
    if ((Test-Path $pOrig) -and ((Get-Item $pOrig).Length -gt 0)) {
        return "/media/" + ($relOrig -replace "\\", "/")
    }
    $pExact = Join-Path $MediaDir ($rel -replace "/", "\")
    if ((Test-Path $pExact) -and ((Get-Item $pExact).Length -gt 0)) {
        return "/media/" + ($rel -replace "\\", "/")
    }
    return ""
}

function Fix-Typos([string]$Text) {
    if (-not $Text) { return "" }
    $t = $Text
    $t = $t -replace "Liên hệ với EuroSpace", "Liên hệ với Nhôm Sắt Hữu Tiến"
    $t = $t -replace "EuroSpace", "Nhôm Sắt Hữu Tiến"
    $t = $t -replace "HŨU TIẾN", "HỮU TIẾN"
    $t = $t -replace "Lắt đặt -Nghiệm thu", "Lắp đặt - Nghiệm thu"
    $t = $t -replace "Lắt đặt", "Lắp đặt"
    $t = $t -replace "Gửi tin nhấn", "Gửi tin nhắn"
    $t = $t -replace "Kính thước", "Kích thước"
    $t = $t -replace "Mái hiênn", "Mái hiên"
    $t = $t -replace "Chuyên cữa", "Chuyên cửa"
    $t = $t -replace "trãi nghiệm", "trải nghiệm"
    $t = $t -replace "chặn đường", "chặng đường"
    $t = $t -replace "Đc 2 : Đc 2 :", "Đc 2 :"
    return $t
}

function Clean-ContentHtml([string]$Html) {
    if (-not $Html) { return "" }
    $h = $Html
    # Remove scripts, styles, comments, wpcf7 forms (we render our own forms)
    $h = [regex]::Replace($h, "(?s)<script[^>]*>.*?</script>", "")
    $h = [regex]::Replace($h, "(?s)<style[^>]*>.*?</style>", "")
    $h = [regex]::Replace($h, "(?s)<!--.*?-->", "")
    # Restore LiteSpeed lazy-loaded iframes/images
    $h = [regex]::Replace($h, 'data-litespeed-src="([^"]+)"', 'src="$1"')
    $h = [regex]::Replace($h, 'src="data:image/svg\+xml[^"]*"\s*', '')
    $h = [regex]::Replace($h, 'data-src="([^"]+)"', 'src="$1"')
    $h = [regex]::Replace($h, '\s+srcset="[^"]*"', '')
    $h = [regex]::Replace($h, '\s+data-srcset="[^"]*"', '')
    $h = [regex]::Replace($h, '\s+sizes="[^"]*"', '')
    $h = [regex]::Replace($h, '\s+data-lazyloaded="[^"]*"', '')
    $h = [regex]::Replace($h, '\s+data-ll-status="[^"]*"', '')
    $h = [regex]::Replace($h, '\s+loading="[^"]*"', '')

    # Rewrite all huutien.net/wp-content/uploads URLs to local /media/...
    $h = [regex]::Replace($h, 'https?://(?:www\.)?huutien\.net/wp-content/uploads/[^\s"''<>)]+', {
        param($m)
        $local = Resolve-LocalMedia $m.Value
        if ($local) { return $local }
        return ""
    })

    # Remove <img> tags with empty src (broken 404 images)
    $h = [regex]::Replace($h, '<img\b[^>]*\bsrc=""[^>]*>', '')
    # Add loading="lazy" to remaining images
    $h = [regex]::Replace($h, '<img\b', '<img loading="lazy"')

    # Rewrite internal huutien.net links to relative paths
    $h = [regex]::Replace($h, 'https?://(?:www\.)?huutien\.net(/[^"''\s<>]*)', '$1')
    $h = [regex]::Replace($h, 'https?://(?:www\.)?huutien\.net(?=["''\s<>])', '/')

    $h = Fix-Typos $h
    return $h.Trim()
}

function Extract-GalleryImages([string]$Html) {
    $list = New-Object System.Collections.ArrayList
    $seen = New-Object System.Collections.Generic.HashSet[string]
    if (-not $Html) { return @() }
    # Extract all /media/... image URLs from cleaned HTML
    $matches = [regex]::Matches($Html, '/media/[^\s"''<>)]+\.(?:jpg|jpeg|png|webp|gif)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    foreach ($m in $matches) {
        $u = $m.Value
        if ($u -match 'Logo-Huutien|favicon') { continue }
        if ($seen.Add($u)) {
            [void]$list.Add($u)
        }
    }
    return @($list)
}

function Strip-Tags([string]$Html) {
    if (-not $Html) { return "" }
    $t = [regex]::Replace($Html, "(?s)<script[^>]*>.*?</script>", " ")
    $t = [regex]::Replace($t, "(?s)<style[^>]*>.*?</style>", " ")
    $t = [regex]::Replace($t, "<[^>]+>", " ")
    $t = Decode-Html $t
    $t = [regex]::Replace($t, "\s+", " ").Trim()
    return $t
}

# Gallery-heavy page slugs where Flatsome renders big photo grids
$gallerySlugs = @("mau-cua-nhom", "cong-hang-rao", "noi-that-inox-nhom", "khung-bao-ve", "cau-thang-lan-can")

Write-Host "Extracting pages..."
$pagesOut = New-Object System.Collections.ArrayList
foreach ($p in $pagesRaw) {
    if ($p.slug -eq "trang-chu") { continue }
    $rawHtml = $p.content.rendered
    $cleaned = Clean-ContentHtml $rawHtml
    $gallery = @()
    if ($gallerySlugs -contains $p.slug) {
        $gallery = @(Extract-GalleryImages $cleaned)
        # Extract intro text (paragraphs/headings outside gallery divs if any)
        $textParts = New-Object System.Collections.ArrayList
        foreach ($m in [regex]::Matches($cleaned, '(?s)<(p|h2|h3|h4|ul|ol)[^>]*>.*?</\1>')) {
            $plain = Strip-Tags $m.Value
            if ($plain.Length -gt 8 -and $m.Value -notmatch '<img\b') {
                [void]$textParts.Add($m.Value)
            }
        }
        $introHtml = ($textParts -join "`n")
    } else {
        $introHtml = ""
    }

    $title = Fix-Typos (Decode-Html $p.title.rendered)
    $excerpt = Strip-Tags $cleaned
    if ($excerpt.Length -gt 180) { $excerpt = $excerpt.Substring(0, 180).Trim() + "..." }

    [void]$pagesOut.Add([ordered]@{
        id = $p.id
        slug = $p.slug
        route = "/$($p.slug)/"
        title = $title
        excerpt = $excerpt
        isGallery = ($gallery.Count -ge 4)
        gallery = $gallery
        introHtml = $introHtml
        contentHtml = $cleaned
        date = ($p.date -split "T")[0]
    })
}

Write-Host "Extracting posts..."
$catMap = @{}
foreach ($c in $catsRaw) {
    $catMap[[string]$c.id] = @{ id = $c.id; slug = $c.slug; name = (Decode-Html $c.name) }
}

$postsOut = New-Object System.Collections.ArrayList
foreach ($p in $postsRaw) {
    $cleaned = Clean-ContentHtml $p.content.rendered
    $featUrl = ""
    if ($p.featured_media -and $mediaById.ContainsKey([string]$p.featured_media)) {
        $featUrl = Resolve-LocalMedia $mediaById[[string]$p.featured_media]
    }
    if (-not $featUrl) {
        $imgs = @(Extract-GalleryImages $cleaned)
        if ($imgs.Count -gt 0) { $featUrl = $imgs[0] }
    }
    $catSlug = "tin-tuc"
    $catName = "Tin tức"
    if ($p.categories -and $p.categories.Count -gt 0) {
        $cid = [string]$p.categories[0]
        if ($catMap.ContainsKey($cid)) {
            $catSlug = $catMap[$cid].slug
            $catName = $catMap[$cid].name
        }
    }
    $title = Fix-Typos (Decode-Html $p.title.rendered)
    $excerpt = Fix-Typos (Strip-Tags $p.excerpt.rendered)
    if (-not $excerpt) {
        $excerpt = Strip-Tags $cleaned
    }
    if ($excerpt.Length -gt 170) { $excerpt = $excerpt.Substring(0, 170).Trim() + "..." }

    [void]$postsOut.Add([ordered]@{
        id = $p.id
        slug = $p.slug
        route = "/$($p.slug)/"
        title = $title
        excerpt = $excerpt
        categorySlug = $catSlug
        categoryName = $catName
        featuredImage = $featUrl
        contentHtml = $cleaned
        date = ($p.date -split "T")[0]
    })
}

Write-Host "Extracting projects (/du-an/...)..."
$projectDefs = @(
    @{ file = "du-an__can-ho__cong-trinh-nha-o-xa-nhon-hoi.html"; route = "/du-an/can-ho/cong-trinh-nha-o-xa-nhon-hoi/"; catSlug = "can-ho"; catName = "Căn hộ"; thumb = "/media/2026/03/xa-Nhon-Hoi.jpg" },
    @{ file = "du-an__can-ho__cong-trinh-nha-o-han-mac-tu.html"; route = "/du-an/can-ho/cong-trinh-nha-o-han-mac-tu/"; catSlug = "can-ho"; catName = "Căn hộ"; thumb = "/media/2026/03/Han-Mac-Tu.jpg" },
    @{ file = "du-an__can-ho__cong-trinh-nha-o-tuy-phuoc.html"; route = "/du-an/can-ho/cong-trinh-nha-o-tuy-phuoc/"; catSlug = "can-ho"; catName = "Căn hộ"; thumb = "/media/2026/03/Tuy-Phuoc.jpg" },
    @{ file = "du-an__can-ho-cao-cap__cong-trinh-biet-thu-gia-dinh.html"; route = "/du-an/can-ho-cao-cap/cong-trinh-biet-thu-gia-dinh/"; catSlug = "can-ho-cao-cap"; catName = "Căn hộ cao cấp"; thumb = "/media/2026/03/Cong-trinh-biet-thu-gia-dinh.jpg" },
    @{ file = "du-an__nha-hang__cong-trinh-kinh-doanh-quan-nhau.html"; route = "/du-an/nha-hang/cong-trinh-kinh-doanh-quan-nhau/"; catSlug = "nha-hang"; catName = "Nhà hàng"; thumb = "/media/2026/03/Cong-trinh-kinh-doanh-quan-nhau.jpg" }
)

$projectsOut = New-Object System.Collections.ArrayList
foreach ($pd in $projectDefs) {
    $fpath = Join-Path $HtmlDir $pd.file
    $raw = [System.IO.File]::ReadAllText($fpath)
    $title = Fix-Typos (Decode-Html (([regex]::Match($raw, '(?s)<h1[^>]*>(.*?)</h1>').Groups[1].Value -replace '<[^>]+>', '').Trim()))
    # Extract main portfolio content
    $mainHtml = [regex]::Match($raw, '(?s)<div class="portfolio-inner[^"]*">.*?</div>\s*</div>\s*</div>').Value
    if (-not $mainHtml) {
        $mainHtml = [regex]::Match($raw, '(?s)<main[^>]*>.*?</main>').Value
    }
    $cleanedMain = Clean-ContentHtml $mainHtml
    # Extract description paragraphs
    $descParts = New-Object System.Collections.ArrayList
    foreach ($m in [regex]::Matches($cleanedMain, '(?s)<p[^>]*>.*?</p>')) {
        $txt = Strip-Tags $m.Value
        if ($txt.Length -gt 15 -and $txt -notmatch 'Chân thành cảm ơn|Copyright') {
            [void]$descParts.Add("<p>$txt</p>")
        }
    }
    # Extract images belonging to this project (exclude related project thumbs)
    $allImgs = @(Extract-GalleryImages $cleanedMain)
    $otherThumbs = @($projectDefs | Where-Object { $_.route -ne $pd.route } | ForEach-Object { $_.thumb })
    $projImgs = New-Object System.Collections.ArrayList
    [void]$projImgs.Add($pd.thumb)
    foreach ($img in $allImgs) {
        if ($img -ne $pd.thumb -and ($otherThumbs -notcontains $img)) {
            [void]$projImgs.Add($img)
        }
    }

    [void]$projectsOut.Add([ordered]@{
        route = $pd.route
        title = $title
        categorySlug = $pd.catSlug
        categoryName = $pd.catName
        thumbnail = $pd.thumb
        gallery = @($projImgs)
        descriptionHtml = ($descParts -join "`n")
    })
}

$data = [ordered]@{
    generatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
    pages = @($pagesOut)
    posts = @($postsOut)
    projects = @($projectsOut)
}

[System.IO.File]::WriteAllText($OutPath, ($data | ConvertTo-Json -Depth 10), [System.Text.UTF8Encoding]::new($false))
Write-Host "Extracted $($pagesOut.Count) pages, $($postsOut.Count) posts, $($projectsOut.Count) projects -> content/data.json"
