import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const distDir = path.join(root, "dist");
const publicDir = path.join(root, "public");

const site = JSON.parse(fs.readFileSync(path.join(root, "content", "site.json"), "utf8"));
const data = JSON.parse(fs.readFileSync(path.join(root, "content", "data.json"), "utf8"));

fs.rmSync(distDir, { recursive: true, force: true });
fs.mkdirSync(distDir, { recursive: true });
fs.cpSync(publicDir, distDir, { recursive: true });

const esc = (s = "") =>
  String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");

const writeRoute = (route, html) => {
  const clean = route.replace(/^\/+|\/+$/g, "");
  let outFile;
  if (!clean) {
    outFile = path.join(distDir, "index.html");
  } else if (clean.endsWith(".html")) {
    outFile = path.join(distDir, clean);
  } else {
    const dir = path.join(distDir, clean);
    fs.mkdirSync(dir, { recursive: true });
    outFile = path.join(dir, "index.html");
  }
  fs.writeFileSync(outFile, html, "utf8");
};

const productMenu = [
  { title: "Cửa nhôm", href: "/cua-nhom/" },
  { title: "Mẫu cửa nhôm", href: "/mau-cua-nhom/" },
  { title: "Cổng hàng rào", href: "/cong-hang-rao/" },
  { title: "Cầu thang – Lan can", href: "/cau-thang-lan-can/" },
  { title: "Khung bảo vệ", href: "/khung-bao-ve/" },
  { title: "Vách kính", href: "/vach-kinh/" },
  { title: "Bản lề sàn", href: "/ban-le-san/" },
  { title: "Mặt dựng", href: "/mat-dung/" },
  { title: "Nội ngoại thất thép hộp mạ kẽm", href: "/noi-ngoai-that-thep-hop-ma-kem/" },
  { title: "Nội thất Inox cao cấp", href: "/noi-that-inox-cao-cap/" },
  { title: "Nội thất Inox Nhôm", href: "/noi-that-inox-nhom/" },
];

const ICO = {
  phone: `<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>`,
  mail: `<svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>`,
  search: `<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/></svg>`,
  menu: `<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/></svg>`,
  up: `<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m18 15-6-6-6 6"/></svg>`,
  check: `<svg class="ico ico-lg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>`,
};

const renderLayout = ({ title, description, route, bodyHtml, includeTurnstile = false }) => {
  const fullTitle = route === "/" ? site.siteName : `${title} | ${site.shortName}`;
  const desc = description || `${site.siteName} - ${site.tagline}`;
  const canonical = `${site.domain}${route}`;
  const prodDropHtml = productMenu.map((m) => `<li><a href="${m.href}">${esc(m.title)}</a></li>`).join("\n");
  const turnstileScript = includeTurnstile
    ? '<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>'
    : "";
  const act = (r) => (route === r ? " active" : "");

  return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${esc(fullTitle)}</title>
  <meta name="description" content="${esc(desc)}">
  <link rel="canonical" href="${canonical}">
  <link rel="icon" href="${site.favicon}" sizes="32x32">
  <meta property="og:type" content="website">
  <meta property="og:title" content="${esc(fullTitle)}">
  <meta property="og:description" content="${esc(desc)}">
  <meta property="og:url" content="${canonical}">
  <meta property="og:image" content="${site.domain}${site.heroSlides[0].image}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/style.css">
  ${turnstileScript}
</head>
<body>
  <div class="topbar">
    <div class="container topbar-inner">
      <div class="topbar-note"><span class="topbar-dot"></span><span>${esc(site.tagline)} · ${esc(site.topbarNote)}</span></div>
      <div class="topbar-links">
        <a class="topbar-hotline" href="tel:${site.contact.phoneHref}">${ICO.phone}<span>Hotline: ${site.contact.phoneDisplay}</span></a>
        <a class="topbar-email" href="mailto:${site.contact.email}">${ICO.mail}<span>${site.contact.email}</span></a>
        <a class="topbar-zalo-mobile" href="${site.contact.zaloUrl}" target="_blank" rel="noopener">Chat Zalo →</a>
      </div>
    </div>
  </div>

  <header class="site-header">
    <div class="container header-inner">
      <a class="brand-logo" href="/" aria-label="${esc(site.siteName)}">
        <img src="${site.logo}" alt="${esc(site.siteName)}" width="160" height="52">
      </a>
      <nav class="main-nav" aria-label="Điều hướng chính">
        <ul class="nav-list">
          <li class="nav-item"><a class="nav-link${act("/")}" href="/">Trang chủ</a></li>
          <li class="nav-item"><a class="nav-link${act("/gioi-thieu/")}" href="/gioi-thieu/">Giới thiệu</a></li>
          <li class="nav-item has-dropdown">
            <a class="nav-link${act("/cua-nhom/")}" href="/cua-nhom/">Sản phẩm ▾</a>
            <ul class="dropdown-menu">${prodDropHtml}</ul>
          </li>
          <li class="nav-item"><a class="nav-link${act("/dich-vu/")}" href="/dich-vu/">Dịch vụ</a></li>
          <li class="nav-item"><a class="nav-link${act("/cong-trinh/")}" href="/cong-trinh/">Công trình</a></li>
          <li class="nav-item"><a class="nav-link${act("/category/tin-tuc/")}" href="/category/tin-tuc/">Tin tức</a></li>
          <li class="nav-item"><a class="nav-link${act("/lien-he/")}" href="/lien-he/">Liên hệ</a></li>
        </ul>
      </nav>
      <div class="header-actions">
        <button class="icon-btn" type="button" data-open-search aria-label="Tìm kiếm">${ICO.search}</button>
        <a class="btn btn-gold btn-sm" href="/yeu-cau-bao-gia/">Yêu cầu báo giá</a>
        <button class="icon-btn menu-toggle" type="button" data-open-drawer aria-label="Mở menu">${ICO.menu}</button>
      </div>
    </div>
  </header>

  <div class="mobile-drawer" id="mobile-drawer" aria-hidden="true">
    <div class="mobile-drawer-panel">
      <div class="drawer-header">
        <img src="${site.logo}" alt="${esc(site.shortName)}">
        <button class="drawer-close" type="button" data-close-drawer aria-label="Đóng">×</button>
      </div>
      <ul class="mobile-nav">
        <li><a href="/">Trang chủ</a></li>
        <li><a href="/gioi-thieu/">Giới thiệu</a></li>
        <li><a href="/cua-nhom/">Sản phẩm</a><ul class="mobile-sub">${prodDropHtml}</ul></li>
        <li><a href="/dich-vu/">Dịch vụ</a></li>
        <li><a href="/cong-trinh/">Công trình</a></li>
        <li><a href="/category/tin-tuc/">Tin tức</a></li>
        <li><a href="/cau-hoi-thuong-gap/">Câu hỏi thường gặp</a></li>
        <li><a href="/lien-he/">Liên hệ</a></li>
        <li><a href="/yeu-cau-bao-gia/" class="btn btn-gold" style="margin-top:8px;text-align:center;">Yêu cầu báo giá</a></li>
      </ul>
    </div>
  </div>

  <main>${bodyHtml}</main>

  <footer class="site-footer">
    <div class="container">
      <div class="footer-grid">
        <div class="footer-contact">
          <h4>Xưởng sản xuất Nhôm Sắt Hữu Tiến</h4>
          <p><strong>Cơ sở 1:</strong> ${site.contact.addresses[0].text}</p>
          <p><strong>Cơ sở 2:</strong> ${site.contact.addresses[1].text}</p>
          <p><strong>Hotline:</strong> <a href="tel:${site.contact.phoneHref}" style="color:#ffe082;font-weight:700">${site.contact.phoneDisplay}</a> (Mr. Tiến)</p>
          <p><strong>Email:</strong> <a href="mailto:${site.contact.email}" style="color:#fff">${site.contact.email}</a></p>
          <p><strong>Website:</strong> ${site.contact.website}</p>
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
          <a class="footer-hotline" href="tel:${site.contact.phoneHref}">📞 ${site.contact.phoneDisplay}</a>
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
    <a class="fab fab-phone" href="tel:${site.contact.phoneHref}" title="Gọi Mr. Tiến: ${site.contact.phoneDisplay}" aria-label="Gọi ngay">${ICO.phone}</a>
    <a class="fab fab-zalo" href="${site.contact.zaloUrl}" target="_blank" rel="noopener" title="Nhắn Zalo Hữu Tiến" aria-label="Zalo">Zalo</a>
    <button class="fab fab-top" id="fab-top" type="button" title="Lên đầu trang" aria-label="Lên đầu trang">${ICO.up}</button>
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
</html>`;
};

const renderContactForm = (heading, sub) => `<div class="form-card">
  <h3>${esc(heading)}</h3>
  <p class="form-sub">${esc(sub)}</p>
  <form data-worker-form="/api/contact" novalidate>
    <input class="hp-field" type="text" name="website_hp" tabindex="-1" autocomplete="off">
    <div class="form-field"><label for="cf-name">Họ và tên *</label><input id="cf-name" name="name" type="text" required placeholder="Nhập họ tên của bạn"></div>
    <div class="form-grid">
      <div class="form-field"><label for="cf-phone">Số điện thoại *</label><input id="cf-phone" name="phone" type="tel" required placeholder="0973 397 206"></div>
      <div class="form-field"><label for="cf-email">Email</label><input id="cf-email" name="email" type="email" placeholder="email@example.com"></div>
    </div>
    <div class="form-field" style="margin-top:14px"><label for="cf-message">Nội dung cần tư vấn *</label><textarea id="cf-message" name="message" rows="4" required placeholder="Mô tả hạng mục cửa nhôm, cổng sắt, kích thước dự kiến..."></textarea></div>
    <div class="turnstile-wrap"><div class="cf-turnstile" data-sitekey="${site.turnstileSiteKey}" data-theme="light"></div></div>
    <div class="form-actions"><button type="submit" class="btn btn-primary">Gửi tin nhắn</button><button type="reset" class="btn btn-outline btn-sm">Nhập lại</button></div>
    <div class="form-status" role="status" aria-live="polite"></div>
  </form>
</div>`;

const renderSidebar = () => {
  const recentHtml = data.posts.slice(0, 6).map((p) => `<li><a href="${p.route}">${esc(p.title)}</a></li>`).join("\n");
  const prodHtml = productMenu.slice(0, 8).map((m) => `<li><a href="${m.href}">${esc(m.title)}</a></li>`).join("\n");
  return `<aside class="sidebar">
    <div class="widget"><h3>Tìm kiếm</h3><form data-sidebar-search style="display:flex;gap:8px"><input type="search" placeholder="Nhập từ khóa..." style="flex:1;padding:10px 12px;border:1.5px solid var(--border);border-radius:8px;font:inherit"><button type="submit" class="btn btn-primary btn-sm">Tìm</button></form></div>
    <div class="widget hotline-widget"><h3>Tư vấn &amp; Báo giá trực tiếp</h3><p>Mr. Tiến – Chủ xưởng trực tiếp khảo sát công trình, tư vấn vật tư và báo giá tốt nhất tại Quy Nhơn.</p><a class="btn btn-gold" style="width:100%;margin-bottom:10px" href="tel:${site.contact.phoneHref}">📞 ${site.contact.phoneDisplay}</a><a class="btn btn-outline-white" style="width:100%" href="/yeu-cau-bao-gia/">Gửi yêu cầu báo giá</a></div>
    <div class="widget"><h3>Danh mục sản phẩm</h3><ul class="widget-list">${prodHtml}</ul></div>
    <div class="widget"><h3>Bài viết mới nhất</h3><ul class="widget-list">${recentHtml}</ul></div>
  </aside>`;
};

const allRoutes = [];
const searchIndex = [];

// 1. Homepage
const slidesHtml = site.heroSlides
  .map((sl, i) => {
    const actClass = i === 0 ? " active" : "";
    if (sl.mode === "banner") {
      return `<div class="hero-slide hero-slide--banner${actClass}">
        <a class="hero-banner-link" href="${sl.ctaHref || "/mau-cua-nhom/"}" aria-label="${esc(sl.alt)}">
          <img class="hero-banner-img" src="${sl.image}" alt="${esc(sl.alt)}">
        </a>
      </div>`;
    }
    return `<div class="hero-slide${actClass}">
      <img class="hero-bg" src="${sl.image}" alt="${esc(sl.alt)}">
      <div class="hero-overlay"></div>
      <div class="container"><div class="hero-content">
        <div class="hero-badge">★ ${esc(sl.badge)}</div>
        <h1>${esc(sl.title)}</h1>
        <p>${esc(sl.subtitle)}</p>
        <div class="hero-cta">
          <a class="btn btn-gold" href="${sl.ctaHref}">${esc(sl.ctaText)}</a>
          <a class="btn btn-outline-white" href="tel:${site.contact.phoneHref}">${ICO.phone} Gọi ${site.contact.phoneDisplay}</a>
        </div>
      </div></div>
    </div>`;
  })
  .join("\n");

const dotsHtml = site.heroSlides
  .map((_, i) => `<button class="hero-dot${i === 0 ? " active" : ""}" type="button" aria-label="Slide ${i + 1}"></button>`)
  .join("");

const featCatsHtml = site.featuredCategories
  .map(
    (c) => `<a class="cat-card" href="${c.href}"><img src="${c.image}" alt="${esc(c.title)}" loading="lazy"><div class="cat-card-body"><h3>${esc(c.title)}</h3><p>${esc(c.subtitle)}</p></div></a>`
  )
  .join("\n");

const quickCatsHtml = site.quickCategories
  .map(
    (c) => `<a class="quick-item" href="${c.href}"><div><h3>${esc(c.title)}</h3><span>${esc(c.desc)}</span></div><span class="quick-arrow">→</span></a>`
  )
  .join("\n");

const processHtml = site.process
  .map(
    (p) => `<div class="process-card"><div class="process-icon-wrap"><span class="process-num">${p.step}</span><img src="${p.icon}" alt="${esc(p.title)}" loading="lazy"></div><h3>${esc(p.title)}</h3><p>${esc(p.desc)}</p></div>`
  )
  .join("\n");

const homeProjectsHtml = data.projects
  .map(
    (p) => `<a class="project-card" href="${p.route}"><div class="project-thumb"><img src="${p.thumbnail}" alt="${esc(p.title)}" loading="lazy"><span class="project-cat-badge">${esc(p.categoryName)}</span></div><div class="project-body"><h3>${esc(p.title)}</h3><span class="more-link">Xem chi tiết công trình →</span></div></a>`
  )
  .join("\n");

const homeNewsHtml = data.posts
  .filter((p) => p.categorySlug === "tin-tuc")
  .slice(0, 4)
  .map(
    (p) => `<a class="news-item" href="${p.route}"><div class="news-item-thumb"><img src="${p.featuredImage}" alt="${esc(p.title)}" loading="lazy"></div><div><div class="news-meta">${p.date} · ${esc(p.categoryName)}</div><h3>${esc(p.title)}</h3><p>${esc(p.excerpt)}</p></div></a>`
  )
  .join("\n");

const reviewsHtml = site.reviews
  .slice(0, 6)
  .map(
    (r) => `<div class="review-card"><div><div class="review-stars" aria-label="5 sao">★★★★★</div><p class="review-text">“${esc(r.text)}”</p></div><div class="review-author"><div class="review-avatar">${esc(r.author[0].toUpperCase())}</div><div><div class="review-name">${esc(r.author)}</div><div class="review-date">Đánh giá trên Google · ${r.date}</div></div></div></div>`
  )
  .join("\n");

const homeBody = `
<section class="hero-slider" data-hero-slider>
  <div class="hero-slides">${slidesHtml}</div>
  <button class="hero-arrow prev" type="button" data-hero-prev aria-label="Slide trước">‹</button>
  <button class="hero-arrow next" type="button" data-hero-next aria-label="Slide tiếp">›</button>
  <div class="hero-controls">${dotsHtml}</div>
</section>
<section class="trust-strip" aria-label="Cam kết Hữu Tiến">
  <div class="container trust-grid">
    <div class="trust-item"><span class="trust-icon">${ICO.check}</span><div><strong>Giá gốc tại xưởng</strong><span>Gia công trực tiếp tại Quy Nhơn</span></div></div>
    <div class="trust-item"><span class="trust-icon">${ICO.check}</span><div><strong>Chủ xưởng giám sát</strong><span>Mr. Tiến trực tiếp tư vấn &amp; đo đạc</span></div></div>
    <div class="trust-item"><span class="trust-icon">${ICO.check}</span><div><strong>Vật tư chính hãng</strong><span>Xingfa, Maxrock, Rocket, Inox</span></div></div>
    <div class="trust-item"><span class="trust-icon">${ICO.check}</span><div><strong>Bảo hành dài hạn</strong><span>Lắp đặt đúng hẹn, bảo trì tận tâm</span></div></div>
  </div>
</section>
<section class="section"><div class="container">
  <div class="section-header"><span class="section-eyebrow">Danh mục sản phẩm</span><h2>Giải pháp Cửa Cổng – Nhôm Kính – Inox Sắt toàn diện</h2><p>Gia công trực tiếp tại xưởng với đa dạng mẫu mã, phù hợp cho nhà phố, biệt thự và công trình kinh doanh.</p></div>
  <div class="cat-featured-grid">${featCatsHtml}</div>
  <div class="quick-grid">${quickCatsHtml}</div>
</div></section>
<section class="section section-soft"><div class="container about-grid">
  <div>
    <span class="section-eyebrow">${esc(site.about.eyebrow)}</span>
    <h2 style="font-size:clamp(1.6rem,2.6vw,2.2rem);margin-bottom:16px">${esc(site.about.title)}</h2>
    ${site.about.paragraphs.map((p) => `<p>${esc(p)}</p>`).join("\n")}
    <ul class="about-checks">${site.about.highlights.map((h) => `<li>${esc(h)}</li>`).join("\n")}</ul>
    <div style="display:flex;gap:12px;flex-wrap:wrap"><a class="btn btn-primary" href="/gioi-thieu/">Xem thêm về Hữu Tiến</a><a class="btn btn-outline" href="/lien-he/">Liên hệ khảo sát</a></div>
  </div>
  <div class="about-media"><img src="${site.about.image}" alt="${esc(site.about.title)}" loading="lazy"></div>
</div></section>
<section class="section section-blue"><div class="container">
  <div class="section-header"><span class="section-eyebrow">Làm việc chuyên nghiệp</span><h2>Quy trình thực hiện</h2><p>Rõ ràng từng bước từ khâu tư vấn, thiết kế, gia công tại xưởng đến lắp đặt nghiệm thu và bảo hành.</p></div>
  <div class="process-grid">${processHtml}</div>
</div></section>
<section class="section"><div class="container">
  <div class="section-header"><span class="section-eyebrow">Dự án thực tế</span><h2>Công trình đã thi công</h2><p>Một số công trình nhà ở, biệt thự và nhà hàng do Xưởng Nhôm Sắt Hữu Tiến trực tiếp thiết kế và lắp đặt.</p></div>
  <div class="projects-grid">${homeProjectsHtml}</div>
  <div style="text-align:center;margin-top:28px"><a class="btn btn-outline" href="/cong-trinh/">Xem tất cả công trình →</a></div>
</div></section>
<section class="section section-soft"><div class="container split-grid">
  <div>
    <span class="section-eyebrow">Cập nhật &amp; Kiến thức</span>
    <h2 style="margin-bottom:18px">Tin tức &amp; Sự kiện</h2>
    <div class="news-list">${homeNewsHtml}</div>
    <div style="margin-top:18px"><a class="btn btn-outline btn-sm" href="/category/tin-tuc/">Xem thêm tin tức →</a></div>
  </div>
  <div>${renderContactForm("Gửi tin nhắn liên hệ", "Để lại thông tin hoặc gọi trực tiếp 0973 397 206 để được Mr. Tiến tư vấn miễn phí.")}</div>
</div></section>
<section class="section"><div class="container">
  <div class="section-header"><span class="section-eyebrow">Uy tín được kiểm chứng</span><h2>Khách hàng đánh giá về Hữu Tiến</h2><p>Đánh giá thực tế từ khách hàng đã thi công cửa nhôm, cổng sắt tại Quy Nhơn trên Google Maps.</p></div>
  <div class="reviews-grid">${reviewsHtml}</div>
</div></section>`;

writeRoute("/", renderLayout({ title: site.siteName, description: site.tagline, route: "/", bodyHtml: homeBody, includeTurnstile: true }));
allRoutes.push("/");

// 2. Contact & Quote
const lienHeBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>Liên hệ</span></div><h1>Liên hệ Nhôm Sắt Hữu Tiến</h1><div class="page-meta">Tư vấn, khảo sát và báo giá trực tiếp tại Quy Nhơn – Bình Định</div></div></section>
<section class="section"><div class="container">
  <div class="contact-cards">
    <div class="contact-info-card"><h3>📍 Địa chỉ xưởng &amp; cơ sở</h3><p><strong>Cơ sở 1:</strong> ${site.contact.addresses[0].text}</p><p><strong>Cơ sở 2:</strong> ${site.contact.addresses[1].text}</p></div>
    <div class="contact-info-card"><h3>📞 Điện thoại &amp; Zalo</h3><p>Hotline: <a href="tel:${site.contact.phoneHref}" style="font-weight:700;font-size:1.05rem">${site.contact.phoneDisplay}</a></p><p>Mr. Tiến – Chủ xưởng trực tiếp tư vấn và giám sát thi công.</p><p><a href="${site.contact.zaloUrl}" target="_blank" rel="noopener">Nhắn tin qua Zalo →</a></p></div>
    <div class="contact-info-card"><h3>✉ Email &amp; Website</h3><p>Email: <a href="mailto:${site.contact.email}">${site.contact.email}</a></p><p>Website: <a href="/">${site.contact.website}</a></p></div>
  </div>
  <div class="split-grid">
    <div class="map-frame"><iframe src="${site.contact.mapEmbedUrl}" loading="lazy" allowfullscreen referrerpolicy="no-referrer-when-downgrade" title="Bản đồ Cửa Cổng Nhôm Sắt Hữu Tiến Quy Nhơn"></iframe></div>
    <div>${renderContactForm("Gửi tin nhắn cho chúng tôi", "Liên hệ với Nhôm Sắt Hữu Tiến qua biểu mẫu dưới đây, chúng tôi sẽ hỗ trợ bạn trong thời gian nhanh nhất.")}</div>
  </div>
</div></section>`;
writeRoute("/lien-he/", renderLayout({ title: "Liên hệ", description: "Liên hệ Xưởng Nhôm Sắt Hữu Tiến Quy Nhơn - Hotline 0973 397 206.", route: "/lien-he/", bodyHtml: lienHeBody, includeTurnstile: true }));
allRoutes.push("/lien-he/");
searchIndex.push({ title: "Liên hệ", route: "/lien-he/", type: "Trang", excerpt: "Địa chỉ xưởng Nhơn Hội và 36 Phan Bá Vành, Quy Nhơn. Hotline 0973 397 206." });

const quoteBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>Yêu cầu báo giá</span></div><h1>Yêu cầu báo giá công trình</h1><div class="page-meta">Điền thông tin hạng mục cửa đi, cửa sổ, cổng sắt – Hữu Tiến gửi báo giá chi tiết trong ngày</div></div></section>
<section class="section"><div class="container content-layout">
  <div class="form-card">
    <h3>Thông tin yêu cầu báo giá</h3>
    <p class="form-sub">Các mục có dấu (*) là bắt buộc. Thông tin càng chi tiết, báo giá sơ bộ sẽ càng sát thực tế.</p>
    <form data-worker-form="/api/quote" novalidate>
      <input class="hp-field" type="text" name="website_hp" tabindex="-1" autocomplete="off">
      <div class="form-grid">
        <div class="form-field"><label for="q-name">Họ tên *</label><input id="q-name" name="ho_ten" type="text" required placeholder="Nhập họ và tên"></div>
        <div class="form-field"><label for="q-phone">Điện thoại *</label><input id="q-phone" name="dien_thoai" type="tel" required placeholder="Số điện thoại liên hệ"></div>
        <div class="form-field"><label for="q-email">Email *</label><input id="q-email" name="email" type="email" required placeholder="email@example.com"></div>
        <div class="form-field"><label for="q-address">Địa chỉ công trình</label><input id="q-address" name="dia_chi" type="text" placeholder="Ví dụ: TP. Quy Nhơn, Bình Định"></div>
        <div class="form-field"><label for="q-proj">Tên công trình</label><input id="q-proj" name="ten_cong_trinh" type="text" placeholder="Nhà phố, biệt thự, quán ăn..."></div>
        <div class="form-field"><label for="q-proj-type">Loại công trình</label><input id="q-proj-type" name="loai_cong_trinh" type="text" placeholder="Nhà ở dân dụng / Căn hộ / Thương mại"></div>
        <div class="form-field full"><label for="q-door-type">Loại cửa / Hạng mục quan tâm</label><input id="q-door-type" name="loai_cua" type="text" placeholder="Nhôm Xingfa, Cổng sắt hộp mạ kẽm, Vách kính, Lan can, Tủ inox nhôm..."></div>
        <div class="form-field"><label for="q-door-qty">Số lượng cửa đi</label><input id="q-door-qty" name="so_luong_cua_di" type="text" placeholder="Ví dụ: 3 bộ"></div>
        <div class="form-field"><label for="q-door-size">Kích thước cửa đi (ước lượng)</label><input id="q-door-size" name="kich_thuoc_cua_di" type="text" placeholder="Ví dụ: 2.4m x 2.6m"></div>
        <div class="form-field"><label for="q-win-qty">Số lượng cửa sổ</label><input id="q-win-qty" name="so_luong_cua_so" type="text" placeholder="Ví dụ: 6 bộ"></div>
        <div class="form-field"><label for="q-win-size">Kích thước cửa sổ (ước lượng)</label><input id="q-win-size" name="kich_thuoc_cua_so" type="text" placeholder="Ví dụ: 1.2m x 1.4m"></div>
        <div class="form-field full"><label for="q-notes">Ghi chú thêm (nếu có)</label><textarea id="q-notes" name="ghi_chu" rows="3" placeholder="Màu sắc nhôm, thời gian dự kiến thi công..."></textarea></div>
      </div>
      <div class="turnstile-wrap"><div class="cf-turnstile" data-sitekey="${site.turnstileSiteKey}" data-theme="light"></div></div>
      <div class="form-actions"><button type="submit" class="btn btn-primary">Gửi yêu cầu báo giá</button><button type="reset" class="btn btn-outline btn-sm">Nhập lại</button></div>
      <div class="form-status" role="status" aria-live="polite"></div>
    </form>
  </div>
  ${renderSidebar()}
</div></section>`;
writeRoute("/yeu-cau-bao-gia/", renderLayout({ title: "Yêu cầu báo giá", description: "Gửi yêu cầu báo giá cửa nhôm Xingfa, cổng sắt, vách kính tại Nhôm Sắt Hữu Tiến Quy Nhơn.", route: "/yeu-cau-bao-gia/", bodyHtml: quoteBody, includeTurnstile: true }));
allRoutes.push("/yeu-cau-bao-gia/");
searchIndex.push({ title: "Yêu cầu báo giá", route: "/yeu-cau-bao-gia/", type: "Trang", excerpt: "Gửi kích thước cửa đi, cửa sổ, hạng mục thi công để nhận báo giá từ Hữu Tiến." });

// 3. Portfolio archives + single projects
const renderPortfolioArchive = (route, heading, filterCat = "all") => {
  const items = filterCat === "all" ? data.projects : data.projects.filter((p) => p.categorySlug === filterCat);
  const cards = items
    .map((p) => `<a class="project-card" href="${p.route}" data-project-cat="${p.categorySlug}"><div class="project-thumb"><img src="${p.thumbnail}" alt="${esc(p.title)}" loading="lazy"><span class="project-cat-badge">${esc(p.categoryName)}</span></div><div class="project-body"><h3>${esc(p.title)}</h3><span class="more-link">Xem chi tiết công trình →</span></div></a>`)
    .join("\n");
  const tabs =
    filterCat === "all"
      ? `<div class="filter-tabs"><button class="filter-btn active" type="button" data-filter="all">Tất cả (${data.projects.length})</button><button class="filter-btn" type="button" data-filter="can-ho">Căn hộ</button><button class="filter-btn" type="button" data-filter="can-ho-cao-cap">Căn hộ cao cấp</button><button class="filter-btn" type="button" data-filter="nha-hang">Nhà hàng</button></div>`
      : "";
  const body = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/cong-trinh/">Công trình</a>${filterCat !== "all" ? ` <span>/</span> <span>${esc(heading)}</span>` : ""}</div><h1>${esc(heading)}</h1><div class="page-meta">Hình ảnh thực tế các công trình do Xưởng Nhôm Sắt Hữu Tiến trực tiếp thi công</div></div></section><section class="section"><div class="container">${tabs}<div class="projects-grid">${cards}</div></div></section>`;
  writeRoute(route, renderLayout({ title: heading, description: "Các công trình cửa nhôm kính, cửa cổng sắt do Nhôm Sắt Hữu Tiến thi công tại Quy Nhơn.", route, bodyHtml: body }));
  allRoutes.push(route);
};

renderPortfolioArchive("/cong-trinh/", "Công trình đã thi công", "all");
renderPortfolioArchive("/featured_item/", "Công trình đã thi công", "all");
renderPortfolioArchive("/du-an/can-ho/", "Công trình Căn hộ", "can-ho");
renderPortfolioArchive("/du-an/can-ho-cao-cap/", "Công trình Căn hộ cao cấp", "can-ho-cao-cap");
renderPortfolioArchive("/du-an/nha-hang/", "Công trình Nhà hàng", "nha-hang");
searchIndex.push({ title: "Công trình đã thi công", route: "/cong-trinh/", type: "Công trình", excerpt: "Danh sách công trình nhà ở, biệt thự, nhà hàng do Hữu Tiến thi công." });

for (const proj of data.projects) {
  const galHtml = proj.gallery.map((g) => `<button class="gallery-item" type="button" data-lightbox-src="${g}" aria-label="Xem ảnh lớn"><img src="${g}" alt="${esc(proj.title)}" loading="lazy"></button>`).join("\n");
  const relHtml = data.projects
    .filter((p) => p.route !== proj.route)
    .slice(0, 3)
    .map((p) => `<a class="project-card" href="${p.route}"><div class="project-thumb"><img src="${p.thumbnail}" alt="${esc(p.title)}" loading="lazy"><span class="project-cat-badge">${esc(p.categoryName)}</span></div><div class="project-body"><h3>${esc(p.title)}</h3></div></a>`)
    .join("\n");
  const pBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/cong-trinh/">Công trình</a> <span>/</span> <a href="/du-an/${proj.categorySlug}/">${esc(proj.categoryName)}</a></div><h1>${esc(proj.title)}</h1></div></section>
<section class="section"><div class="container content-layout"><div class="article-body"><div class="gallery-grid" style="margin-bottom:24px">${galHtml}</div>${proj.descriptionHtml}<div style="margin-top:26px;padding:18px;background:var(--brand-blue-soft);border-radius:12px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px"><div><strong>Bạn cần thi công hạng mục tương tự?</strong><br><span style="font-size:0.9rem;color:var(--ink-muted)">Gọi Mr. Tiến (${site.contact.phoneDisplay}) để được khảo sát miễn phí.</span></div><a class="btn btn-primary btn-sm" href="/yeu-cau-bao-gia/">Yêu cầu báo giá</a></div></div>${renderSidebar()}</div><div class="container" style="margin-top:48px"><h2 style="margin-bottom:20px">Công trình khác</h2><div class="projects-grid">${relHtml}</div></div></section>`;
  writeRoute(proj.route, renderLayout({ title: proj.title, description: `${proj.title} - Công trình thi công bởi Nhôm Sắt Hữu Tiến Quy Nhơn.`, route: proj.route, bodyHtml: pBody }));
  allRoutes.push(proj.route);
  searchIndex.push({ title: proj.title, route: proj.route, type: "Công trình", excerpt: proj.categoryName });
}

// 4. Regular & Gallery pages
const specialSlugs = new Set(["lien-he", "yeu-cau-bao-gia", "cong-trinh", "dich-vu"]);
for (const pg of data.pages) {
  if (specialSlugs.has(pg.slug)) continue;
  const innerHtml = pg.isGallery
    ? `${pg.introHtml ? `<div style="margin-bottom:24px">${pg.introHtml}</div>` : ""}<p style="color:var(--ink-muted);margin-bottom:18px">Bộ sưu tập <strong>${pg.gallery.length} hình ảnh thực tế</strong> – bấm vào từng ảnh để phóng to.</p><div class="gallery-grid">${pg.gallery.map((g) => `<button class="gallery-item" type="button" data-lightbox-src="${g}" aria-label="Phóng to ảnh ${esc(pg.title)}"><img src="${g}" alt="${esc(pg.title)}" loading="lazy"></button>`).join("\n")}</div>`
    : pg.contentHtml;
  const pageBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>${esc(pg.title)}</span></div><h1>${esc(pg.title)}</h1></div></section><section class="section"><div class="container content-layout"><article class="article-body">${innerHtml}</article>${renderSidebar()}</div></section>`;
  writeRoute(pg.route, renderLayout({ title: pg.title, description: pg.excerpt, route: pg.route, bodyHtml: pageBody }));
  allRoutes.push(pg.route);
  searchIndex.push({ title: pg.title, route: pg.route, type: "Sản phẩm / Trang", excerpt: pg.excerpt });
}

// 5. Blog archives (/category/tin-tuc/, /category/dich-vu/, /dich-vu/) & single posts
for (const bc of [
  { slug: "tin-tuc", name: "Tin tức & Kiến thức", route: "/category/tin-tuc/", subtitle: "Cập nhật kiến thức chọn cửa nhôm, thước lỗ ban và tin tức từ Hữu Tiến" },
  { slug: "dich-vu", name: "Dịch vụ", route: "/category/dich-vu/", subtitle: "Tư vấn, gia công, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành – bảo trì" },
  { slug: "dich-vu", name: "Dịch vụ", route: "/dich-vu/", subtitle: "Tư vấn, gia công, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành – bảo trì" },
]) {
  const catPosts = data.posts.filter((p) => p.categorySlug === bc.slug);
  const cardsHtml = catPosts
    .map((p) => `<article class="post-card"><a class="post-card-img" href="${p.route}"><img src="${p.featuredImage}" alt="${esc(p.title)}" loading="lazy"></a><div class="post-card-body"><div class="news-meta">${p.date} · ${esc(p.categoryName)}</div><h3><a href="${p.route}">${esc(p.title)}</a></h3><p>${esc(p.excerpt)}</p></div></article>`)
    .join("\n");
  const catBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <span>${esc(bc.name)}</span></div><h1>${esc(bc.name)}</h1><div class="page-meta">${esc(bc.subtitle)} (${catPosts.length} bài viết)</div></div></section><section class="section"><div class="container"><div class="posts-grid">${cardsHtml}</div></div></section>`;
  writeRoute(bc.route, renderLayout({ title: bc.name, description: `${bc.name} tại Nhôm Sắt Hữu Tiến Quy Nhơn.`, route: bc.route, bodyHtml: catBody }));
  allRoutes.push(bc.route);
}
searchIndex.push({ title: "Dịch vụ", route: "/dich-vu/", type: "Dịch vụ", excerpt: "Tư vấn dịch vụ, lắp đặt nghiệm thu, cam kết chất lượng và bảo hành bảo trì." });

for (const post of data.posts) {
  const related = data.posts.filter((p) => p.slug !== post.slug && p.categorySlug === post.categorySlug).slice(0, 3);
  const relHtml = related
    .map((p) => `<article class="post-card"><a class="post-card-img" href="${p.route}"><img src="${p.featuredImage}" alt="${esc(p.title)}" loading="lazy"></a><div class="post-card-body"><div class="news-meta">${p.date}</div><h3><a href="${p.route}">${esc(p.title)}</a></h3></div></article>`)
    .join("\n");
  const featHtml = post.featuredImage && !post.contentHtml.includes(post.featuredImage) ? `<img src="${post.featuredImage}" alt="${esc(post.title)}" style="margin-top:0;width:100%;max-height:460px;object-fit:cover">` : "";
  const postBody = `<section class="page-banner"><div class="container"><div class="breadcrumbs"><a href="/">Trang chủ</a> <span>/</span> <a href="/category/${post.categorySlug}/">${esc(post.categoryName)}</a> <span>/</span> <span>${esc(post.title)}</span></div><h1>${esc(post.title)}</h1><div class="page-meta">Ngày đăng: ${post.date} · Chuyên mục: ${esc(post.categoryName)}</div></div></section>
<section class="section"><div class="container content-layout"><article class="article-body">${featHtml}${post.contentHtml}</article>${renderSidebar()}</div>${related.length ? `<div class="container" style="margin-top:48px"><h2 style="margin-bottom:20px">Bài viết liên quan</h2><div class="posts-grid">${relHtml}</div></div>` : ""}</section>`;
  writeRoute(post.route, renderLayout({ title: post.title, description: post.excerpt, route: post.route, bodyHtml: postBody }));
  allRoutes.push(post.route);
  searchIndex.push({ title: post.title, route: post.route, type: post.categoryName, excerpt: post.excerpt });
}

// 6. 404, Search Index, Sitemap, Robots, Headers
writeRoute(
  "404.html",
  renderLayout({
    title: "404 - Không tìm thấy trang",
    description: "Không tìm thấy trang.",
    route: "/404.html",
    bodyHtml: `<section class="section" style="text-align:center;padding:96px 0"><div class="container" style="max-width:560px"><div style="font-size:4rem;font-weight:800;color:var(--brand-blue);line-height:1">404</div><h1 style="margin:12px 0">Không tìm thấy trang</h1><p style="color:var(--ink-muted);margin-bottom:26px">Đường dẫn bạn truy cập không tồn tại hoặc đã được di chuyển.</p><div style="display:flex;justify-content:center;gap:12px;flex-wrap:wrap"><a class="btn btn-primary" href="/">Về trang chủ</a><a class="btn btn-outline" href="/lien-he/">Liên hệ hỗ trợ</a></div></div></section>`,
  })
);
fs.writeFileSync(path.join(distDir, "search-index.json"), JSON.stringify(searchIndex, null, 2), "utf8");
const today = new Date().toISOString().slice(0, 10);
const uniqueRoutes = [...new Set(allRoutes)].sort();
fs.writeFileSync(
  path.join(distDir, "sitemap.xml"),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${uniqueRoutes.map((r) => `  <url><loc>${site.domain}${r}</loc><lastmod>${today}</lastmod></url>`).join("\n")}\n</urlset>\n`,
  "utf8"
);
fs.writeFileSync(path.join(distDir, "robots.txt"), `User-agent: *\nAllow: /\nSitemap: ${site.domain}/sitemap.xml\n`, "utf8");
fs.writeFileSync(
  path.join(distDir, "_headers"),
  `/*\n  X-Content-Type-Options: nosniff\n  X-Frame-Options: SAMEORIGIN\n  Referrer-Policy: strict-origin-when-cross-origin\n\n/assets/*\n  Cache-Control: public, max-age=31536000, immutable\n\n/media/*\n  Cache-Control: public, max-age=31536000, immutable\n`,
  "utf8"
);
console.log(`BUILD COMPLETE! Generated ${uniqueRoutes.length} routes + 404.html + sitemap.xml + search-index.json`);
