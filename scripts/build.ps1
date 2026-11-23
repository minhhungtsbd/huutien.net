$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$DistDir = Join-Path $Root "dist"
$PublicDir = Join-Path $Root "public"

$site = Get-Content (Join-Path $Root "content\site.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$data = Get-Content (Join-Path $Root "content\data.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# Clean dist
if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# Copy public assets & media into dist
Copy-Item -Path (Join-Path $PublicDir "*") -Destination $DistDir -Recurse -Force

function Esc([string]$s) {
    if (-not $s) { return "" }
    return [System.Net.WebUtility]::HtmlEncode($s)
}

function Write-RouteHtml([string]$Route, [string]$Html) {
    $clean = $Route.Trim("/")
    if (-not $clean) {
        $outFile = Join-Path $DistDir "index.html"
    } elseif ($clean.EndsWith(".html")) {
        $outFile = Join-Path $DistDir $clean
    } else {
        $dir = Join-Path $DistDir ($clean -replace "/", "\")
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $outFile = Join-Path $dir "index.html"
    }
    [System.IO.File]::WriteAllText($outFile, $Html, [System.Text.UTF8Encoding]::new($false))
}

$productMenu = @(
    @{ title = "Cửa nhôm"; href = "/cua-nhom/" },
    @{ title = "Mẫu cửa nhôm"; href = "/mau-cua-nhom/" },
    @{ title = "Cổng hàng rào"; href = "/cong-hang-rao/" },
    @{ title = "Cầu thang – Lan can"; href = "/cau-thang-lan-can/" },
    @{ title = "Khung bảo vệ"; href = "/khung-bao-ve/" },
    @{ title = "Vách kính"; href = "/vach-kinh/" },
    @{ title = "Bản lề sàn"; href = "/ban-le-san/" },
    @{ title = "Mặt dựng"; href = "/mat-dung/" },
    @{ title = "Nội ngoại thất thép hộp mạ kẽm"; href = "/noi-ngoai-that-thep-hop-ma-kem/" },
    @{ title = "Nội thất Inox cao cấp"; href = "/noi-that-inox-cao-cap/" },
    @{ title = "Nội thất Inox Nhôm"; href = "/noi-that-inox-nhom/" }
)

$ICO = @{
    phone  = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>'
    mail   = '<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>'
    search = '<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>'
    menu   = '<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/></svg>'
    up     = '<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m18 15-6-6-6 6"/></svg>'
    check  = '<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>'
}

function Render-Layout {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Route,
        [string]$BodyHtml,
        [bool]$IncludeTurnstile = $false
    )
    $fullTitle = if ($Route -eq "/") { $site.siteName } else { "$Title | $($site.shortName)" }
    $desc = if ($Description) { $Description } else { "$($site.siteName) - $($site.tagline)" }
    $canonical = "$($site.domain)$Route"

    $prodDropHtml = ($productMenu | ForEach-Object { "<li><a href=`"$($_.href)`">$(Esc $_.title)</a></li>" }) -join "`n"
    $turnstileScript = if ($IncludeTurnstile) { '<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>' } else { '' }

    $navActive = {
        param($r)
        if ($Route -eq $r) { ' active' } else { '' }
    }

    return @"
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$(Esc $fullTitle)</title>
  <meta name="description" content="$(Esc $desc)">
  <link rel="canonical" href="$canonical">
  <link rel="icon" href="$($site.favicon)" sizes="32x32">
  <meta property="og:type" content="website">
  <meta property="og:title" content="$(Esc $fullTitle)">
  <meta property="og:description" content="$(Esc $desc)">
  <meta property="og:url" content="$canonical">
  <meta property="og:image" content="$($site.domain)$($site.heroSlides[0].image)">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/style.css">
  $turnstileScript
</head>
<body>
  <div class="topbar">
    <div class="container topbar-inner">
      <div class="topbar-note"><span class="topbar-dot"></span><span>$(Esc $site.tagline) · $(Esc $site.topbarNote)</span></div>
      <div class="topbar-links">
        <a class="topbar-hotline" href="tel:$($site.contact.phoneHref)">$($ICO.phone)<span>Hotline: $($site.contact.phoneDisplay)</span></a>
        <a class="topbar-email" href="mailto:$($site.contact.email)">$($ICO.mail)<span>$($site.contact.email)</span></a>
        <a class="topbar-zalo-mobile" href="$($site.contact.zaloUrl)" target="_blank" rel="noopener">Chat Zalo →</a>
      </div>
    </div>
  </div>

  <header class="site-header">
    <div class="container header-inner">
      <a class="brand-logo" href="/" aria-label="$(Esc $site.siteName)">
        <img src="$($site.logo)" alt="$(Esc $site.siteName)" width="160" height="52">
      </a>

      <nav class="main-nav" aria-label="Điều hướng chính">
        <ul class="nav-list">
          <li class="nav-item"><a class="nav-link$(& $navActive '/')" href="/">Trang chủ</a></li>
          <li class="nav-item"><a class="nav-link$(& $navActive '/gioi-thieu/')" href="/gioi-thieu/">Giới thiệu</a></li>
          <li class="nav-item has-dropdown">
            <a class="nav-link$(& $navActive '/cua-nhom/')" href="/cua-nhom/">Sản phẩm ▾</a>
            <ul class="dropdown-menu">
              $prodDropHtml
            </ul>
          </li>
          <li class="nav-item"><a class="nav-link$(& $navActive '/dich-vu/')" href="/dich-vu/">Dịch vụ</a></li>
          <li class="nav-item"><a class="nav-link$(& $navActive '/cong-trinh/')" href="/cong-trinh/">Công trình</a></li>
          <li class="nav-item"><a class="nav-link$(& $navActive '/category/tin-tuc/')" href="/category/tin-tuc/">Tin tức</a></li>
          <li class="nav-item"><a class="nav-link$(& $navActive '/lien-he/')" href="/lien-he/">Liên hệ</a></li>
        </ul>
      </nav>

      <div class="header-actions">
        <button class="icon-btn" type="button" data-open-search aria-label="Tìm kiếm">$($ICO.search)</button>
        <a class="btn btn-gold btn-sm" href="/yeu-cau-bao-gia/">Yêu cầu báo giá</a>
        <button class="icon-btn menu-toggle" type="button" data-open-drawer aria-label="Mở menu">$($ICO.menu)</button>
      </div>
    </div>
  </header>

  <div class="mobile-drawer" id="mobile-drawer" aria-hidden="true">
    <div class="mobile-drawer-panel">
      <div class="drawer-header">
        <img src="$($site.logo)" alt="$(Esc $site.shortName)">
        <button class="drawer-close" type="button" data-close-drawer aria-label="Đóng">×</button>
      </div>
      <ul class="mobile-nav">
        <li><a href="/">Trang chủ</a></li>
        <li><a href="/gioi-thieu/">Giới thiệu</a></li>
        <li>
          <a href="/cua-nhom/">Sản phẩm</a>
          <ul class="mobile-sub">$prodDropHtml</ul>
        </li>
        <li><a href="/dich-vu/">Dịch vụ</a></li>
        <li><a href="/cong-trinh/">Công trình</a></li>
        <li><a href="/category/tin-tuc/">Tin tức</a></li>
        <li><a href="/cau-hoi-thuong-gap/">Câu hỏi thường gặp</a></li>
        <li><a href="/lien-he/">Liên hệ</a></li>
        <li><a href="/yeu-cau-bao-gia/" class="btn btn-gold" style="margin-top:8px;text-align:center;">Yêu cầu báo giá</a></li>
      </ul>
    </div>
  </div>

  <main>
    $BodyHtml
  </main>

  <footer class="site-footer">
    <div class="container">
      <div class="footer-grid">
        <div class="footer-contact">
          <h4>Xưởng sản xuất Nhôm Sắt Hữu Tiến</h4>
          <p><strong>Cơ sở 1:</strong> $($site.contact.addresses[0].text)</p>
          <p><strong>Cơ sở 2:</strong> $($site.contact.addresses[1].text)</p>
          <p><strong>Hotline:</strong> <a href="tel:$($site.contact.phoneHref)" style="color:#ffe082;font-weight:700">$($site.contact.phoneDisplay)</a> (Mr. Tiến)</p>
          <p><strong>Email:</strong> <a href="mailto:$($site.contact.email)" style="color:#fff">$($site.contact.email)</a></p>
          <p><strong>Website:</strong> $($site.contact.website)</p>
        </div>

        <div>
          <h4>Về chúng tôi</h4>
          <ul class="footer-links">
            <li><a href="/gioi-thieu/">Giới thiệu</a></li>
            <li><a href="/cua-nhom/">Sản phẩm</a></li>
            <li><a href="/dich-vu/">Dịch vụ</a></li>
            <li><a href="/cong-trinh/">Công trình đã thi công</a></li>
            <li><a href="/category/tin-tuc/">Tin tức &amp; Kiến thức</a></li>
            <li><a href="/lien-he/">Liên hệ</a></li>
          </ul>
        </div>

        <div>
          <h4>Sản phẩm chính</h4>
          <ul class="footer-links">
            <li><a href="/cua-nhom/">Cửa nhôm cao cấp</a></li>
            <li><a href="/mau-cua-nhom/">Mẫu cửa nhôm đẹp</a></li>
            <li><a href="/vach-kinh/">Vách kính – Mặt dựng</a></li>
            <li><a href="/ban-le-san/">Cửa kính bản lề sàn</a></li>
            <li><a href="/cong-hang-rao/">Cổng sắt – Hàng rào</a></li>
            <li><a href="/cau-thang-lan-can/">Cầu thang – Lan can</a></li>
            <li><a href="/noi-that-inox-nhom/">Tủ &amp; Nội thất Inox Nhôm</a></li>
          </ul>
        </div>

        <div>
          <h4>Hỗ trợ khách hàng</h4>
          <a class="footer-hotline" href="tel:$($site.contact.phoneHref)">📞 $($site.contact.phoneDisplay)</a>
          <ul class="footer-links">
            <li><a href="/bao-hanh-bao-tri/">Chính sách bảo hành – bảo trì</a></li>
            <li><a href="/cam-ket-chat-luong/">Cam kết chất lượng</a></li>
            <li><a href="/lat-dat-nghiem-thu/">Quy trình lắp đặt – nghiệm thu</a></li>
            <li><a href="/cau-hoi-thuong-gap/">Câu hỏi thường gặp</a></li>
            <li><a href="/yeu-cau-bao-gia/">Yêu cầu báo giá nhanh</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <span>Chân thành cảm ơn Quý Khách đã tin tưởng và ủng hộ Nhôm Sắt Hữu Tiến.</span>
        <span>Copyright © 2026 huutien.net – Cửa Cổng Nhôm Sắt Hữu Tiến Quy Nhơn</span>
      </div>
    </div>
  </footer>

  <div class="floating-bar" aria-label="Liên hệ nhanh">
    <a class="fab fab-phone" href="tel:$($site.contact.phoneHref)" title="Gọi Mr. Tiến: $($site.contact.phoneDisplay)" aria-label="Gọi ngay">$($ICO.phone)</a>
    <a class="fab fab-zalo" href="$($site.contact.zaloUrl)" target="_blank" rel="noopener" title="Nhắn Zalo Hữu Tiến" aria-label="Zalo">Zalo</a>
    <button class="fab fab-top" id="fab-top" type="button" title="Lên đầu trang" aria-label="Lên đầu trang">$($ICO.up)</button>
  </div>

  <div class="search-modal" id="search-modal" role="dialog" aria-modal="true" aria-label="Tìm kiếm">
    <div class="search-box">
      <div class="search-input-wrap">
        <span>🔍</span>
        <input id="search-input" type="search" placeholder="Tìm sản phẩm, mẫu cửa, công trình, tin tức..." autocomplete="off">
        <button class="drawer-close" type="button" data-close-search aria-label="Đóng">×</button>
      </div>
      <div class="search-results" id="search-results"></div>
    </div>
  </div>

  <div class="lightbox" id="lightbox" role="dialog" aria-modal="true" aria-label="Xem ảnh lớn">
    <button class="lightbox-btn lightbox-close" id="lightbox-close" type="button" aria-label="Đóng">×</button>
    <button class="lightbox-btn lightbox-prev" id="lightbox-prev" type="button" aria-label="Ảnh trước">‹</button>
    <img id="lightbox-img" src="" alt="Hình ảnh phóng to">
    <button class="lightbox-btn lightbox-next" id="lightbox-next" type="button" aria-label="Ảnh tiếp theo">›</button>
    <div class="lightbox-counter" id="lightbox-counter"></div>
  </div>

  <script src="/assets/site.js" defer></script>
</body>
</html>
"@
}

function Render-ContactForm([string]$Heading = "Gửi tin nhắn liên hệ", [string]$Sub = "Điền thông tin bên dưới, Mr. Tiến sẽ liên hệ tư vấn và báo giá nhanh nhất.") {
    return @"
<div class="form-card">
  <h3>$(Esc $Heading)</h3>
  <p class="form-sub">$(Esc $Sub)</p>
  <form data-worker-form="/api/contact" novalidate>
    <input class="hp-field" type="text" name="website_hp" tabindex="-1" autocomplete="off">
    <div class="form-field">
      <label for="cf-name">Họ và tên *</label>
      <input id="cf-name" name="name" type="text" required placeholder="Nhập họ tên của bạn">
    </div>
    <div class="form-grid">
      <div class="form-field">
        <label for="cf-phone">Số điện thoại *</label>
        <input id="cf-phone" name="phone" type="tel" required placeholder="0973 397 206">
      </div>
      <div class="form-field">
        <label for="cf-email">Email</label>
        <input id="cf-email" name="email" type="email" placeholder="email@example.com">
      </div>
    </div>
    <div class="form-field" style="margin-top:14px">
      <label for="cf-message">Nội dung cần tư vấn *</label>
      <textarea id="cf-message" name="message" rows="4" required placeholder="Mô tả hạng mục cửa nhôm, cổng sắt, kích thước dự kiến..."></textarea>
    </div>
    <div class="turnstile-wrap">
      <div class="cf-turnstile" data-sitekey="$($site.turnstileSiteKey)" data-theme="light"></div>
    </div>
    <div class="form-actions">
      <button type="submit" class="btn btn-primary">Gửi tin nhắn</button>
      <button type="reset" class="btn btn-outline btn-sm">Nhập lại</button>
    </div>
    <div class="form-status" role="status" aria-live="polite"></div>
  </form>
</div>
"@
}

function Render-Sidebar {
    $recentPosts = $data.posts | Select-Object -First 6
    $recentHtml = ($recentPosts | ForEach-Object { "<li><a href=`"$($_.route)`">$(Esc $_.title)</a></li>" }) -join "`n"
    $prodHtml = ($productMenu | Select-Object -First 8 | ForEach-Object { "<li><a href=`"$($_.href)`">$(Esc $_.title)</a></li>" }) -join "`n"
    return @"
<aside class="sidebar">
  <div class="widget">
    <h3>Tìm kiếm</h3>
    <form data-sidebar-search style="display:flex;gap:8px">
      <input type="search" placeholder="Nhập từ khóa..." style="flex:1;padding:10px 12px;border:1.5px solid var(--border);border-radius:8px;font:inherit">
      <button type="submit" class="btn btn-primary btn-sm">Tìm</button>
    </form>
  </div>
  <div class="widget hotline-widget">
    <h3>Tư vấn &amp; Báo giá trực tiếp</h3>
    <p>Mr. Tiến – Chủ xưởng trực tiếp khảo sát công trình, tư vấn vật tư và báo giá tốt nhất tại Quy Nhơn.</p>
    <a class="btn btn-gold" style="width:100%;margin-bottom:10px" href="tel:$($site.contact.phoneHref)">📞 $($site.contact.phoneDisplay)</a>
    <a class="btn btn-outline-white" style="width:100%" href="/yeu-cau-bao-gia/">Gửi yêu cầu báo giá</a>
  </div>
  <div class="widget">
    <h3>Danh mục sản phẩm</h3>
    <ul class="widget-list">$prodHtml</ul>
  </div>
  <div class="widget">
    <h3>Bài viết mới nhất</h3>
    <ul class="widget-list">$recentHtml</ul>
  </div>
</aside>
"@
}

$allRoutes = New-Object System.Collections.ArrayList
$searchIndex = New-Object System.Collections.ArrayList

# ==========================================================================
# 1. HOMEPAGE (/)
# ==========================================================================
Write-Host "Building Homepage..."
$slidesHtml = ""
for ($i = 0; $i -lt $site.heroSlides.Count; $i++) {
    $sl = $site.heroSlides[$i]
    $act = if ($i -eq 0) { " active" } else { "" }
    if ($sl.mode -eq "banner") {
        $slidesHtml += @"
    <div class="hero-slide hero-slide--banner$act">
      <a class="hero-banner-link" href="$($sl.ctaHref)" aria-label="$(Esc $sl.alt)">
        <img class="hero-banner-img" src="$($sl.image)" alt="$(Esc $sl.alt)">
      </a>
    </div>
"@
    } else {
        $slidesHtml += @"
    <div class="hero-slide$act">
      <img class="hero-bg" src="$($sl.image)" alt="$(Esc $sl.alt)">
      <div class="hero-overlay"></div>
      <div class="container">
        <div class="hero-content">
          <div class="hero-badge">★ $(Esc $sl.badge)</div>
          <h1>$(Esc $sl.title)</h1>
          <p>$(Esc $sl.subtitle)</p>
          <div class="hero-cta">
            <a class="btn btn-gold" href="$($sl.ctaHref)">$(Esc $sl.ctaText)</a>
            <a class="btn btn-outline-white" href="tel:$($site.contact.phoneHref)">$($ICO.phone) Gọi $($site.contact.phoneDisplay)</a>
          </div>
        </div>
      </div>
    </div>
"@
    }
}
$dotsHtml = ""
for ($i = 0; $i -lt $site.heroSlides.Count; $i++) {
    $act = if ($i -eq 0) { " active" } else { "" }
    $dotsHtml += "<button class=`"hero-dot$act`" type=`"button`" aria-label=`"Slide $($i+1)`"></button>"
}

$featCatsHtml = ($site.featuredCategories | ForEach-Object {
    @"
    <a class="cat-card" href="$($_.href)">
      <img src="$($_.image)" alt="$(Esc $_.title)" loading="lazy">
      <div class="cat-card-body">
        <h3>$(Esc $_.title)</h3>
        <p>$(Esc $_.subtitle)</p>
      </div>
    </a>
"@
}) -join "`n"

$quickCatsHtml = ($site.quickCategories | ForEach-Object {
    @"
    <a class="quick-item" href="$($_.href)">
      <div>
        <h3>$(Esc $_.title)</h3>
        <span>$(Esc $_.desc)</span>
      </div>
      <span class="quick-arrow">→</span>
    </a>
"@
}) -join "`n"

$aboutParas = ($site.about.paragraphs | ForEach-Object { "<p>$(Esc $_)</p>" }) -join "`n"
$aboutChecks = ($site.about.highlights | ForEach-Object { "<li>$(Esc $_)</li>" }) -join "`n"

$processHtml = ($site.process | ForEach-Object {
    @"
    <div class="process-card">
      <div class="process-icon-wrap">
        <span class="process-num">$($_.step)</span>
        <img src="$($_.icon)" alt="$(Esc $_.title)" loading="lazy">
      </div>
      <h3>$(Esc $_.title)</h3>
      <p>$(Esc $_.desc)</p>
    </div>
"@
}) -join "`n"

$homeProjectsHtml = ($data.projects | ForEach-Object {
    @"
    <a class="project-card" href="$($_.route)">
      <div class="project-thumb">
        <img src="$($_.thumbnail)" alt="$(Esc $_.title)" loading="lazy">
        <span class="project-cat-badge">$(Esc $_.categoryName)</span>
      </div>
      <div class="project-body">
        <h3>$(Esc $_.title)</h3>
        <span class="more-link">Xem chi tiết công trình →</span>
      </div>
    </a>
"@
}) -join "`n"

$homeNews = $data.posts | Where-Object { $_.categorySlug -eq "tin-tuc" } | Select-Object -First 4
$homeNewsHtml = ($homeNews | ForEach-Object {
    @"
    <a class="news-item" href="$($_.route)">
      <div class="news-item-thumb"><img src="$($_.featuredImage)" alt="$(Esc $_.title)" loading="lazy"></div>
      <div>
        <div class="news-meta">$($_.date) · $(Esc $_.categoryName)</div>
        <h3>$(Esc $_.title)</h3>
        <p>$(Esc $_.excerpt)</p>
      </div>
    </a>
"@
}) -join "`n"

$reviewsHtml = ($site.reviews | Select-Object -First 6 | ForEach-Object {
    $init = $_.author.Substring(0, 1).ToUpper()
    @"
    <div class="review-card">
      <div>
        <div class="review-stars" aria-label="5 sao">★★★★★</div>
        <p class="review-text">“$(Esc $_.text)”</p>
      </div>
      <div class="review-author">
        <div class="review-avatar">$init</div>
        <div>
          <div class="review-name">$(Esc $_.author)</div>
          <div class="review-date">Đánh giá trên Google · $($_.date)</div>
        </div>
      </div>
    </div>
"@
}) -join "`n"

$homeBody = @"
<section class="hero-slider" data-hero-slider>
  <div class="hero-slides">$slidesHtml</div>
  <button class="hero-arrow prev" type="button" data-hero-prev aria-label="Slide trước">‹</button>
  <button class="hero-arrow next" type="button" data-hero-next aria-label="Slide tiếp">›</button>
  <div class="hero-controls">$dotsHtml</div>
</section>

<section class="trust-strip" aria-label="Cam kết Hữu Tiến">
  <div class="container trust-grid">
    <div class="trust-item"><span class="trust-icon">$($ICO.check)</span><div><strong>Giá gốc tại xưởng</strong><span>Gia công trực tiếp tại Quy Nhơn</span></div></div>
    <div class="trust-item"><span class="trust-icon">$($ICO.check)</span><div><strong>Chủ xưởng giám sát</strong><span>Mr. Tiến trực tiếp tư vấn &amp; đo đạc</span></div></div>
    <div class="trust-item"><span class="trust-icon">$($ICO.check)</span><div><strong>Vật tư chính hãng</strong><span>Xingfa, Maxrock, Rocket, Inox</span></div></div>
    <div class="trust-item"><span class="trust-icon">$($ICO.check)</span><div><strong>Bảo hành dài hạn</strong><span>Lắp đặt đúng hẹn, bảo trì tận tâm</span></div></div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="section-header">
      <span class="section-eyebrow">Danh mục sản phẩm</span>
      <h2>Giải pháp Cửa Cổng – Nhôm Kính – Inox Sắt toàn diện</h2>
      <p>Gia công trực tiếp tại xưởng với đa dạng mẫu mã, phù hợp cho nhà phố, biệt thự và công trình kinh doanh.</p>
    </div>
    <div class="cat-featured-grid">$featCatsHtml</div>
    <div class="quick-grid">$quickCatsHtml</div>
  </div>
</section>

<section class="section section-soft">
  <div class="container about-grid">
    <div>
      <span class="section-eyebrow">$(Esc $site.about.eyebrow)</span>
      <h2 style="font-size:clamp(1.6rem,2.6vw,2.2rem);margin-bottom:16px">$(Esc $site.about.title)</h2>
      $aboutParas
      <ul class="about-checks">$aboutChecks</ul>
      <div style="display:flex;gap:12px;flex-wrap:wrap">
        <a class="btn btn-primary" href="/gioi-thieu/">Xem thêm về Hữu Tiến</a>
        <a class="btn btn-outline" href="/lien-he/">Liên hệ khảo sát</a>
      </div>
    </div>
    <div class="about-media">
      <img src="$($site.about.image)" alt="$(Esc $site.about.title)" loading="lazy">
    </div>
  </div>
</section>

<section class="section section-blue">
  <div class="container">
    <div class="section-header">
      <span class="section-eyebrow">Làm việc chuyên nghiệp</span>
      <h2>Quy trình thực hiện</h2>
      <p>Rõ ràng từng bước từ khâu tư vấn, thiết kế, gia công tại xưởng đến lắp đặt nghiệm thu và bảo hành.</p>
    </div>
    <div class="process-grid">$processHtml</div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="section-header">
      <span class="section-eyebrow">Dự án thực tế</span>
      <h2>Công trình đã thi công</h2>
      <p>Một số công trình nhà ở, biệt thự và nhà hàng do Xưởng Nhôm Sắt Hữu Tiến trực tiếp thiết kế và lắp đặt.</p>
    </div>
    <div class="projects-grid">$homeProjectsHtml</div>
    <div style="text-align:center;margin-top:28px">
      <a class="btn btn-outline" href="/cong-trinh/">Xem tất cả công trình →</a>
    </div>
  </div>
</section>

<section class="section section-soft">
  <div class="container split-grid">
    <div>
      <span class="section-eyebrow">Cập nhật &amp; Kiến thức</span>
      <h2 style="margin-bottom:18px">Tin tức &amp; Sự kiện</h2>
      <div class="news-list">$homeNewsHtml</div>
      <div style="margin-top:18px">
        <a class="btn btn-outline btn-sm" href="/category/tin-tuc/">Xem thêm tin tức →</a>
      </div>
    </div>
    <div>
      $(Render-ContactForm "Gửi tin nhắn liên hệ" "Để lại thông tin hoặc gọi trực tiếp 0973 397 206 để được Mr. Tiến tư vấn miễn phí.")
    </div>
  </div>
</section>

<section class="section">
  <div class="container">
    <div class="section-header">
      <span class="section-eyebrow">Uy tín được kiểm chứng</span>
      <h2>Khách hàng đánh giá về Hữu Tiến</h2>
      <p>Đánh giá thực tế từ khách hàng đã thi công cửa nhôm, cổng sắt tại Quy Nhơn trên Google Maps.</p>
    </div>
    <div class="reviews-grid">$reviewsHtml</div>
  </div>
</section>
"@

Write-RouteHtml "/" (Render-Layout -Title $site.siteName -Description $site.tagline -Route "/" -BodyHtml $homeBody -IncludeTurnstile $true)
[void]$allRoutes.Add("/")

# ==========================================================================
# 2. SPECIAL PAGES: /lien-he/, /yeu-cau-bao-gia/, /cong-trinh/
# ==========================================================================
Write-Host "Building Contact, Quote, and Portfolio pages..."

# /lien-he/
$lienHeBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>Liên hệ</span></div>
    <h1>Liên hệ Nhôm Sắt Hữu Tiến</h1>
    <div class="page-meta">Tư vấn, khảo sát và báo giá trực tiếp tại Quy Nhơn – Bình Định</div>
  </div>
</section>
<section class="section">
  <div class="container">
    <div class="contact-cards">
      <div class="contact-info-card">
        <h3>📍 Địa chỉ xưởng &amp; cơ sở</h3>
        <p><strong>Cơ sở 1:</strong> $($site.contact.addresses[0].text)</p>
        <p><strong>Cơ sở 2:</strong> $($site.contact.addresses[1].text)</p>
      </div>
      <div class="contact-info-card">
        <h3>📞 Điện thoại &amp; Zalo</h3>
        <p>Hotline: <a href="tel:$($site.contact.phoneHref)" style="font-weight:700;font-size:1.05rem">$($site.contact.phoneDisplay)</a></p>
        <p>Mr. Tiến – Chủ xưởng trực tiếp tư vấn và giám sát thi công.</p>
        <p><a href="$($site.contact.zaloUrl)" target="_blank" rel="noopener">Nhắn tin qua Zalo →</a></p>
      </div>
      <div class="contact-info-card">
        <h3>✉ Email &amp; Website</h3>
        <p>Email: <a href="mailto:$($site.contact.email)">$($site.contact.email)</a></p>
        <p>Website: <a href="/">$($site.contact.website)</a></p>
      </div>
    </div>

    <div class="split-grid">
      <div class="map-frame">
        <iframe src="$($site.contact.mapEmbedUrl)" loading="lazy" allowfullscreen referrerpolicy="no-referrer-when-downgrade" title="Bản đồ Cửa Cổng Nhôm Sắt Hữu Tiến Quy Nhơn"></iframe>
      </div>
      <div>
        $(Render-ContactForm "Gửi tin nhắn cho chúng tôi" "Liên hệ với Nhôm Sắt Hữu Tiến qua biểu mẫu dưới đây, chúng tôi sẽ hỗ trợ bạn trong thời gian nhanh nhất.")
      </div>
    </div>
  </div>
</section>
"@
Write-RouteHtml "/lien-he/" (Render-Layout -Title "Liên hệ" -Description "Liên hệ Xưởng Nhôm Sắt Hữu Tiến Quy Nhơn - Hotline 0973 397 206." -Route "/lien-he/" -BodyHtml $lienHeBody -IncludeTurnstile $true)
[void]$allRoutes.Add("/lien-he/")
[void]$searchIndex.Add(@{ title = "Liên hệ"; route = "/lien-he/"; type = "Trang"; excerpt = "Địa chỉ xưởng Nhơn Hội và 36 Phan Bá Vành, Quy Nhơn. Hotline 0973 397 206." })

# /yeu-cau-bao-gia/
$quoteBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>Yêu cầu báo giá</span></div>
    <h1>Yêu cầu báo giá công trình</h1>
    <div class="page-meta">Điền thông tin hạng mục cửa đi, cửa sổ, cổng sắt – Hữu Tiến gửi báo giá chi tiết trong ngày</div>
  </div>
</section>
<section class="section">
  <div class="container content-layout">
    <div class="form-card">
      <h3>Thông tin yêu cầu báo giá</h3>
      <p class="form-sub">Các mục có dấu (*) là bắt buộc. Thông tin càng chi tiết, báo giá sơ bộ sẽ càng sát thực tế.</p>
      <form data-worker-form="/api/quote" novalidate>
        <input class="hp-field" type="text" name="website_hp" tabindex="-1" autocomplete="off">
        <div class="form-grid">
          <div class="form-field">
            <label for="q-name">Họ tên *</label>
            <input id="q-name" name="ho_ten" type="text" required placeholder="Nhập họ và tên">
          </div>
          <div class="form-field">
            <label for="q-phone">Điện thoại *</label>
            <input id="q-phone" name="dien_thoai" type="tel" required placeholder="Số điện thoại liên hệ">
          </div>
          <div class="form-field">
            <label for="q-email">Email *</label>
            <input id="q-email" name="email" type="email" required placeholder="email@example.com">
          </div>
          <div class="form-field">
            <label for="q-address">Địa chỉ công trình</label>
            <input id="q-address" name="dia_chi" type="text" placeholder="Ví dụ: TP. Quy Nhơn, Bình Định">
          </div>
          <div class="form-field">
            <label for="q-proj">Tên công trình</label>
            <input id="q-proj" name="ten_cong_trinh" type="text" placeholder="Nhà phố, biệt thự, quán ăn...">
          </div>
          <div class="form-field">
            <label for="q-proj-type">Loại công trình</label>
            <input id="q-proj-type" name="loai_cong_trinh" type="text" placeholder="Nhà ở dân dụng / Căn hộ / Thương mại">
          </div>
          <div class="form-field full">
            <label for="q-door-type">Loại cửa / Hạng mục quan tâm</label>
            <input id="q-door-type" name="loai_cua" type="text" placeholder="Nhôm Xingfa, Cổng sắt hộp mạ kẽm, Vách kính, Lan can, Tủ inox nhôm...">
          </div>
          <div class="form-field">
            <label for="q-door-qty">Số lượng cửa đi</label>
            <input id="q-door-qty" name="so_luong_cua_di" type="text" placeholder="Ví dụ: 3 bộ">
          </div>
          <div class="form-field">
            <label for="q-door-size">Kích thước cửa đi (ước lượng)</label>
            <input id="q-door-size" name="kich_thuoc_cua_di" type="text" placeholder="Ví dụ: 2.4m x 2.6m">
          </div>
          <div class="form-field">
            <label for="q-win-qty">Số lượng cửa sổ</label>
            <input id="q-win-qty" name="so_luong_cua_so" type="text" placeholder="Ví dụ: 6 bộ">
          </div>
          <div class="form-field">
            <label for="q-win-size">Kích thước cửa sổ (ước lượng)</label>
            <input id="q-win-size" name="kich_thuoc_cua_so" type="text" placeholder="Ví dụ: 1.2m x 1.4m">
          </div>
          <div class="form-field full">
            <label for="q-notes">Ghi chú thêm (nếu có)</label>
            <textarea id="q-notes" name="ghi_chu" rows="3" placeholder="Màu sắc nhôm, thời gian dự kiến thi công..."></textarea>
          </div>
        </div>
        <div class="turnstile-wrap">
          <div class="cf-turnstile" data-sitekey="$($site.turnstileSiteKey)" data-theme="light"></div>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn btn-primary">Gửi yêu cầu báo giá</button>
          <button type="reset" class="btn btn-outline btn-sm">Nhập lại</button>
        </div>
        <div class="form-status" role="status" aria-live="polite"></div>
      </form>
    </div>
    $(Render-Sidebar)
  </div>
</section>
"@
Write-RouteHtml "/yeu-cau-bao-gia/" (Render-Layout -Title "Yêu cầu báo giá" -Description "Gửi yêu cầu báo giá cửa nhôm Xingfa, cổng sắt, vách kính tại Nhôm Sắt Hữu Tiến Quy Nhơn." -Route "/yeu-cau-bao-gia/" -BodyHtml $quoteBody -IncludeTurnstile $true)
[void]$allRoutes.Add("/yeu-cau-bao-gia/")
[void]$searchIndex.Add(@{ title = "Yêu cầu báo giá"; route = "/yeu-cau-bao-gia/"; type = "Trang"; excerpt = "Gửi kích thước cửa đi, cửa sổ, hạng mục thi công để nhận báo giá từ Hữu Tiến." })

# /cong-trinh/ & /featured_item/
function Render-PortfolioArchive([string]$Route, [string]$Heading, [string]$FilterCat = "all") {
    $items = if ($FilterCat -eq "all") { $data.projects } else { @($data.projects | Where-Object { $_.categorySlug -eq $FilterCat }) }
    $cards = ($items | ForEach-Object {
        @"
        <a class="project-card" href="$($_.route)" data-project-cat="$($_.categorySlug)">
          <div class="project-thumb">
            <img src="$($_.thumbnail)" alt="$(Esc $_.title)" loading="lazy">
            <span class="project-cat-badge">$(Esc $_.categoryName)</span>
          </div>
          <div class="project-body">
            <h3>$(Esc $_.title)</h3>
            <span class="more-link">Xem chi tiết công trình →</span>
          </div>
        </a>
"@
    }) -join "`n"

    $tabs = if ($FilterCat -eq "all") {
        @"
        <div class="filter-tabs">
          <button class="filter-btn active" type="button" data-filter="all">Tất cả ($($data.projects.Count))</button>
          <button class="filter-btn" type="button" data-filter="can-ho">Căn hộ</button>
          <button class="filter-btn" type="button" data-filter="can-ho-cao-cap">Căn hộ cao cấp</button>
          <button class="filter-btn" type="button" data-filter="nha-hang">Nhà hàng</button>
        </div>
"@
    } else { "" }

    $body = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/cong-trinh/">Công trình</a>$(if ($FilterCat -ne 'all') { " <span>/</span> <span>$(Esc $Heading)</span>" })</div>
    <h1>$(Esc $Heading)</h1>
    <div class="page-meta">Hình ảnh thực tế các công trình do Xưởng Nhôm Sắt Hữu Tiến trực tiếp thi công</div>
  </div>
</section>
<section class="section">
  <div class="container">
    $tabs
    <div class="projects-grid">$cards</div>
  </div>
</section>
"@
    Write-RouteHtml $Route (Render-Layout -Title $Heading -Description "Các công trình cửa nhôm kính, cửa cổng sắt do Nhôm Sắt Hữu Tiến thi công tại Quy Nhơn." -Route $Route -BodyHtml $body)
    [void]$allRoutes.Add($Route)
}

Render-PortfolioArchive "/cong-trinh/" "Công trình đã thi công" "all"
Render-PortfolioArchive "/featured_item/" "Công trình đã thi công" "all"
Render-PortfolioArchive "/du-an/can-ho/" "Công trình Căn hộ" "can-ho"
Render-PortfolioArchive "/du-an/can-ho-cao-cap/" "Công trình Căn hộ cao cấp" "can-ho-cao-cap"
Render-PortfolioArchive "/du-an/nha-hang/" "Công trình Nhà hàng" "nha-hang"
[void]$searchIndex.Add(@{ title = "Công trình đã thi công"; route = "/cong-trinh/"; type = "Công trình"; excerpt = "Danh sách công trình nhà ở, biệt thự, nhà hàng do Hữu Tiến thi công." })

# Single Project pages (/du-an/...)
foreach ($proj in $data.projects) {
    $galHtml = ($proj.gallery | ForEach-Object {
        "<button class=`"gallery-item`" type=`"button`" data-lightbox-src=`"$_`" aria-label=`"Xem ảnh lớn`"><img src=`"$_`" alt=`"$(Esc $proj.title)`" loading=`"lazy`"></button>"
    }) -join "`n"
    $related = @($data.projects | Where-Object { $_.route -ne $proj.route } | Select-Object -First 3)
    $relHtml = ($related | ForEach-Object {
        @"
        <a class="project-card" href="$($_.route)">
          <div class="project-thumb"><img src="$($_.thumbnail)" alt="$(Esc $_.title)" loading="lazy"><span class="project-cat-badge">$(Esc $_.categoryName)</span></div>
          <div class="project-body"><h3>$(Esc $_.title)</h3></div>
        </a>
"@
    }) -join "`n"

    $galClass = if ($proj.gallery.Count -eq 1) { "gallery-grid gallery-grid--single" } else { "gallery-grid" }
    $pBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/cong-trinh/">Công trình</a> <span>/</span> <a href="/du-an/$($proj.categorySlug)/">$(Esc $proj.categoryName)</a></div>
    <h1>$(Esc $proj.title)</h1>
  </div>
</section>
<section class="section">
  <div class="container content-layout">
    <div class="article-body">
      <div class="$galClass" style="margin-bottom:24px">$galHtml</div>
      $($proj.descriptionHtml)
      <div style="margin-top:26px;padding:18px;background:var(--brand-blue-soft);border-radius:12px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px">
        <div><strong>Bạn cần thi công hạng mục tương tự?</strong><br><span style="font-size:0.9rem;color:var(--ink-muted)">Gọi Mr. Tiến ($($site.contact.phoneDisplay)) để được khảo sát miễn phí.</span></div>
        <a class="btn btn-primary btn-sm" href="/yeu-cau-bao-gia/">Yêu cầu báo giá</a>
      </div>
    </div>
    $(Render-Sidebar)
  </div>
  <div class="container" style="margin-top:48px">
    <h2 style="margin-bottom:20px">Công trình khác</h2>
    <div class="projects-grid">$relHtml</div>
  </div>
</section>
"@
    Write-RouteHtml $proj.route (Render-Layout -Title $proj.title -Description "$($proj.title) - Công trình thi công bởi Nhôm Sắt Hữu Tiến Quy Nhơn." -Route $proj.route -BodyHtml $pBody)
    [void]$allRoutes.Add($proj.route)
    [void]$searchIndex.Add(@{ title = $proj.title; route = $proj.route; type = "Công trình"; excerpt = $proj.categoryName })
}

# ==========================================================================
# 3. REGULAR & GALLERY PAGES
# ==========================================================================
Write-Host "Building regular and gallery pages..."
$specialSlugs = @("lien-he", "yeu-cau-bao-gia", "cong-trinh", "dich-vu")
foreach ($pg in $data.pages) {
    if ($specialSlugs -contains $pg.slug) { continue }

    if ($pg.isGallery) {
        $galCards = ($pg.gallery | ForEach-Object {
            "<button class=`"gallery-item`" type=`"button`" data-lightbox-src=`"$_`" aria-label=`"Phóng to ảnh $(Esc $pg.title)`"><img src=`"$_`" alt=`"$(Esc $pg.title)`" loading=`"lazy`"></button>"
        }) -join "`n"
        $innerHtml = @"
        $(if ($pg.introHtml) { "<div style=`"margin-bottom:24px`">$($pg.introHtml)</div>" })
        <p style="color:var(--ink-muted);margin-bottom:18px">Bộ sưu tập <strong>$($pg.gallery.Count) hình ảnh thực tế</strong> – bấm vào từng ảnh để phóng to.</p>
        <div class="gallery-grid">$galCards</div>
"@
    } else {
        $innerHtml = $pg.contentHtml
    }

    $pageBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>$(Esc $pg.title)</span></div>
    <h1>$(Esc $pg.title)</h1>
  </div>
</section>
<section class="section">
  <div class="container content-layout">
    <article class="article-body">
      $innerHtml
    </article>
    $(Render-Sidebar)
  </div>
</section>
"@
    Write-RouteHtml $pg.route (Render-Layout -Title $pg.title -Description $pg.excerpt -Route $pg.route -BodyHtml $pageBody)
    [void]$allRoutes.Add($pg.route)
    [void]$searchIndex.Add(@{ title = $pg.title; route = $pg.route; type = "Sản phẩm / Trang"; excerpt = $pg.excerpt })
}

# ==========================================================================
# 4. BLOG CATEGORY ARCHIVES (/category/tin-tuc/, /category/dich-vu/, /dich-vu/) & SINGLE POSTS
# ==========================================================================
Write-Host "Building blog categories and posts..."
$blogCats = @(
    @{ slug = "tin-tuc"; name = "Tin tức & Kiến thức"; route = "/category/tin-tuc/"; subtitle = "Cập nhật kiến thức chọn cửa nhôm, thước lỗ ban và tin tức từ Hữu Tiến" },
    @{ slug = "dich-vu"; name = "Dịch vụ"; route = "/category/dich-vu/"; subtitle = "Tư vấn, gia công, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành – bảo trì" },
    @{ slug = "dich-vu"; name = "Dịch vụ"; route = "/dich-vu/"; subtitle = "Tư vấn, gia công, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành – bảo trì" }
)

foreach ($bc in $blogCats) {
    $catPosts = @($data.posts | Where-Object { $_.categorySlug -eq $bc.slug })
    $cardsHtml = ($catPosts | ForEach-Object {
        @"
        <article class="post-card">
          <a class="post-card-img" href="$($_.route)">
            <img src="$($_.featuredImage)" alt="$(Esc $_.title)" loading="lazy">
          </a>
          <div class="post-card-body">
            <div class="news-meta">$($_.date) · $(Esc $_.categoryName)</div>
            <h3><a href="$($_.route)">$(Esc $_.title)</a></h3>
            <p>$(Esc $_.excerpt)</p>
          </div>
        </article>
"@
    }) -join "`n"

    $catBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>$(Esc $bc.name)</span></div>
    <h1>$(Esc $bc.name)</h1>
    <div class="page-meta">$(Esc $bc.subtitle) ($($catPosts.Count) bài viết)</div>
  </div>
</section>
<section class="section">
  <div class="container">
    <div class="posts-grid">$cardsHtml</div>
  </div>
</section>
"@
    Write-RouteHtml $bc.route (Render-Layout -Title $bc.name -Description "$($bc.name) tại Nhôm Sắt Hữu Tiến Quy Nhơn." -Route $bc.route -BodyHtml $catBody)
    [void]$allRoutes.Add($bc.route)
}
[void]$searchIndex.Add(@{ title = "Dịch vụ"; route = "/dich-vu/"; type = "Dịch vụ"; excerpt = "Tư vấn dịch vụ, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành bảo trì." })

foreach ($post in $data.posts) {
    $relatedPosts = @($data.posts | Where-Object { $_.slug -ne $post.slug -and $_.categorySlug -eq $post.categorySlug } | Select-Object -First 3)
    $relPostsHtml = ($relatedPosts | ForEach-Object {
        @"
        <article class="post-card">
          <a class="post-card-img" href="$($_.route)"><img src="$($_.featuredImage)" alt="$(Esc $_.title)" loading="lazy"></a>
          <div class="post-card-body">
            <div class="news-meta">$($_.date)</div>
            <h3><a href="$($_.route)">$(Esc $_.title)</a></h3>
          </div>
        </article>
"@
    }) -join "`n"

    $postBody = @"
<section class="page-banner">
  <div class="container">
    <div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/category/$($post.categorySlug)/">$(Esc $post.categoryName)</a> <span>/</span> <span>$(Esc $post.title)</span></div>
    <h1>$(Esc $post.title)</h1>
    <div class="page-meta">Ngày đăng: $($post.date) · Chuyên mục: $(Esc $post.categoryName)</div>
  </div>
</section>
<section class="section">
  <div class="container content-layout">
    <article class="article-body">
      $(if ($post.featuredImage -and ($post.contentHtml -notmatch [regex]::Escape($post.featuredImage))) { "<img src=`"$($post.featuredImage)`" alt=`"$(Esc $post.title)`" style=`"margin-top:0;width:100%;max-height:460px;object-fit:cover`">" })
      $($post.contentHtml)
    </article>
    $(Render-Sidebar)
  </div>
  $(if ($relatedPosts.Count -gt 0) {
    "<div class=`"container`" style=`"margin-top:48px`"><h2 style=`"margin-bottom:20px`">Bài viết liên quan</h2><div class=`"posts-grid`">$relPostsHtml</div></div>"
  })
</section>
"@
    Write-RouteHtml $post.route (Render-Layout -Title $post.title -Description $post.excerpt -Route $post.route -BodyHtml $postBody)
    [void]$allRoutes.Add($post.route)
    [void]$searchIndex.Add(@{ title = $post.title; route = $post.route; type = $post.categoryName; excerpt = $post.excerpt })
}

# ==========================================================================
# 5. 404 PAGE, SEARCH INDEX, SITEMAP, ROBOTS, _HEADERS
# ==========================================================================
$notFoundBody = @"
<section class="section" style="text-align:center;padding:96px 0">
  <div class="container" style="max-width:560px">
    <div style="font-size:4rem;font-weight:800;color:var(--brand-blue);line-height:1">404</div>
    <h1 style="margin:12px 0">Không tìm thấy trang</h1>
    <p style="color:var(--ink-muted);margin-bottom:26px">Đường dẫn bạn truy cập không tồn tại hoặc đã được di chuyển. Mời bạn quay lại trang chủ hoặc tìm kiếm nội dung cần xem.</p>
    <div style="display:flex;justify-content:center;gap:12px;flex-wrap:wrap">
      <a class="btn btn-primary" href="/">Về trang chủ</a>
      <a class="btn btn-outline" href="/lien-he/">Liên hệ hỗ trợ</a>
    </div>
  </div>
</section>
"@
Write-RouteHtml "404.html" (Render-Layout -Title "404 - Không tìm thấy trang" -Description "Không tìm thấy trang." -Route "/404.html" -BodyHtml $notFoundBody)

[System.IO.File]::WriteAllText((Join-Path $DistDir "search-index.json"), (@($searchIndex) | ConvertTo-Json -Depth 4), [System.Text.UTF8Encoding]::new($false))

$today = (Get-Date).ToString("yyyy-MM-dd")
$urlEntries = ($allRoutes | Select-Object -Unique | Sort-Object | ForEach-Object {
    "  <url><loc>$($site.domain)$_</loc><lastmod>$today</lastmod></url>"
}) -join "`n"
$sitemap = @"
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$urlEntries
</urlset>
"@
[System.IO.File]::WriteAllText((Join-Path $DistDir "sitemap.xml"), $sitemap, [System.Text.UTF8Encoding]::new($false))

$robots = @"
User-agent: *
Allow: /
Sitemap: $($site.domain)/sitemap.xml
"@
[System.IO.File]::WriteAllText((Join-Path $DistDir "robots.txt"), $robots, [System.Text.UTF8Encoding]::new($false))

$headers = @"
/*
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
  Referrer-Policy: strict-origin-when-cross-origin

/assets/*
  Cache-Control: public, max-age=31536000, immutable

/media/*
  Cache-Control: public, max-age=31536000, immutable
"@
[System.IO.File]::WriteAllText((Join-Path $DistDir "_headers"), $headers, [System.Text.UTF8Encoding]::new($false))

Write-Host "BUILD COMPLETE! Generated $($allRoutes.Count) routes + 404.html + sitemap.xml + search-index.json in dist/"
