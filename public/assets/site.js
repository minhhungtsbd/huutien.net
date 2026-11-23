/* ==========================================================================
   Cửa Cổng Nhôm Sắt Hữu Tiến – Interactive Client Script
   ========================================================================== */
(function () {
  "use strict";

  // 1. Hero Slider
  const slider = document.querySelector("[data-hero-slider]");
  if (slider) {
    const slides = Array.from(slider.querySelectorAll(".hero-slide"));
    const dots = Array.from(slider.querySelectorAll(".hero-dot"));
    let idx = 0;
    let timer = null;

    const show = (next) => {
      idx = (next + slides.length) % slides.length;
      slides.forEach((s, i) => s.classList.toggle("active", i === idx));
      dots.forEach((d, i) => d.classList.toggle("active", i === idx));
    };

    const start = () => {
      stop();
      timer = setInterval(() => show(idx + 1), 6500);
    };
    const stop = () => {
      if (timer) clearInterval(timer);
    };

    slider.querySelector("[data-hero-prev]")?.addEventListener("click", () => { show(idx - 1); start(); });
    slider.querySelector("[data-hero-next]")?.addEventListener("click", () => { show(idx + 1); start(); });
    dots.forEach((d, i) => d.addEventListener("click", () => { show(i); start(); }));
    slider.addEventListener("mouseenter", stop);
    slider.addEventListener("mouseleave", start);
    if (slides.length > 1) start();
  }

  // 2. Mobile Navigation Drawer
  const drawer = document.getElementById("mobile-drawer");
  const openDrawerBtn = document.querySelector("[data-open-drawer]");
  const closeDrawerBtns = document.querySelectorAll("[data-close-drawer]");
  if (drawer && openDrawerBtn) {
    const toggleDrawer = (open) => {
      drawer.classList.toggle("open", open);
      document.body.style.overflow = open ? "hidden" : "";
    };
    openDrawerBtn.addEventListener("click", () => toggleDrawer(true));
    closeDrawerBtns.forEach((b) => b.addEventListener("click", () => toggleDrawer(false)));
    drawer.addEventListener("click", (e) => { if (e.target === drawer) toggleDrawer(false); });
  }

  // 3. Instant Vietnamese Search Modal
  const searchModal = document.getElementById("search-modal");
  const searchInput = document.getElementById("search-input");
  const searchResults = document.getElementById("search-results");
  let searchData = null;

  const normalizeVi = (str) =>
    (str || "")
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "d");

  const openSearch = async () => {
    if (!searchModal) return;
    searchModal.classList.add("open");
    document.body.style.overflow = "hidden";
    searchInput?.focus();
    if (!searchData) {
      try {
        const r = await fetch("/search-index.json");
        searchData = await r.json();
        renderSearch("");
      } catch {
        if (searchResults) searchResults.innerHTML = '<p style="padding:14px;color:#666">Không tải được dữ liệu tìm kiếm.</p>';
      }
    }
  };

  const closeSearch = () => {
    if (!searchModal) return;
    searchModal.classList.remove("open");
    document.body.style.overflow = "";
  };

  const renderSearch = (q) => {
    if (!searchResults || !searchData) return;
    const nq = normalizeVi(q.trim());
    const matches = nq
      ? searchData.filter((item) => normalizeVi(item.title + " " + item.excerpt + " " + item.type).includes(nq))
      : searchData.slice(0, 8);

    if (!matches.length) {
      searchResults.innerHTML = '<p style="padding:16px;color:#64748b;margin:0">Không tìm thấy kết quả phù hợp.</p>';
      return;
    }
    searchResults.innerHTML = matches
      .slice(0, 12)
      .map(
        (m) =>
          `<a class="search-result-item" href="${m.route}"><strong>${m.title}</strong><small>${m.type}${m.excerpt ? " · " + m.excerpt.slice(0, 95) : ""}</small></a>`
      )
      .join("");
  };

  document.querySelectorAll("[data-open-search]").forEach((btn) => btn.addEventListener("click", openSearch));
  document.querySelectorAll("[data-close-search]").forEach((btn) => btn.addEventListener("click", closeSearch));
  searchModal?.addEventListener("click", (e) => { if (e.target === searchModal) closeSearch(); });
  searchInput?.addEventListener("input", (e) => renderSearch(e.target.value));
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      closeSearch();
      closeLightbox();
    }
  });

  // Inline sidebar search trigger
  document.querySelectorAll("[data-sidebar-search]").forEach((form) => {
    form.addEventListener("submit", (e) => {
      e.preventDefault();
      const val = form.querySelector("input")?.value || "";
      openSearch().then(() => {
        if (searchInput) {
          searchInput.value = val;
          renderSearch(val);
        }
      });
    });
  });

  // 4. Portfolio Category Filter
  const filterBtns = document.querySelectorAll("[data-filter]");
  if (filterBtns.length) {
    const cards = document.querySelectorAll("[data-project-cat]");
    filterBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const cat = btn.getAttribute("data-filter");
        filterBtns.forEach((b) => b.classList.toggle("active", b === btn));
        cards.forEach((c) => {
          const match = cat === "all" || c.getAttribute("data-project-cat") === cat;
          c.style.display = match ? "" : "none";
        });
      });
    });
  }

  // 5. Lightbox for Gallery & Project Photos
  const lightbox = document.getElementById("lightbox");
  const lightboxImg = document.getElementById("lightbox-img");
  const lightboxCounter = document.getElementById("lightbox-counter");
  let galleryList = [];
  let galleryIdx = 0;

  const openLightbox = (list, startIdx) => {
    if (!lightbox || !lightboxImg) return;
    galleryList = list;
    galleryIdx = startIdx;
    updateLightbox();
    lightbox.classList.add("open");
    document.body.style.overflow = "hidden";
  };

  const closeLightbox = () => {
    if (!lightbox) return;
    lightbox.classList.remove("open");
    document.body.style.overflow = "";
  };

  const updateLightbox = () => {
    if (!galleryList.length) return;
    galleryIdx = (galleryIdx + galleryList.length) % galleryList.length;
    lightboxImg.src = galleryList[galleryIdx];
    if (lightboxCounter) lightboxCounter.textContent = `${galleryIdx + 1} / ${galleryList.length}`;
  };

  const galleryTriggers = Array.from(document.querySelectorAll("[data-lightbox-src]"));
  if (galleryTriggers.length) {
    const srcs = galleryTriggers.map((el) => el.getAttribute("data-lightbox-src"));
    galleryTriggers.forEach((el, i) => {
      el.addEventListener("click", () => openLightbox(srcs, i));
    });
  }
  document.getElementById("lightbox-close")?.addEventListener("click", closeLightbox);
  document.getElementById("lightbox-prev")?.addEventListener("click", () => { galleryIdx--; updateLightbox(); });
  document.getElementById("lightbox-next")?.addEventListener("click", () => { galleryIdx++; updateLightbox(); });
  lightbox?.addEventListener("click", (e) => { if (e.target === lightbox) closeLightbox(); });
  document.addEventListener("keydown", (e) => {
    if (!lightbox?.classList.contains("open")) return;
    if (e.key === "ArrowLeft") { galleryIdx--; updateLightbox(); }
    if (e.key === "ArrowRight") { galleryIdx++; updateLightbox(); }
  });

  // 6. Scroll to top button
  const topBtn = document.getElementById("fab-top");
  if (topBtn) {
    window.addEventListener("scroll", () => {
      topBtn.classList.toggle("show", window.scrollY > 360);
    }, { passive: true });
    topBtn.addEventListener("click", () => window.scrollTo({ top: 0, behavior: "smooth" }));
  }

  // 7. Cloudflare Worker Forms (Contact & Quote)
  document.querySelectorAll("form[data-worker-form]").forEach((form) => {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const statusEl = form.querySelector(".form-status");
      const submitBtn = form.querySelector('button[type="submit"]');
      const endpoint = form.getAttribute("data-worker-form");
      const origText = submitBtn ? submitBtn.textContent : "";

      if (statusEl) {
        statusEl.className = "form-status";
        statusEl.textContent = "";
      }
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = "Đang gửi...";
      }

      try {
        const fd = new FormData(form);
        const payload = {};
        fd.forEach((v, k) => { payload[k] = typeof v === "string" ? v.trim() : v; });

        const resp = await fetch(endpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });
        const data = await resp.json().catch(() => ({}));

        if (resp.ok && data.ok) {
          if (statusEl) {
            statusEl.className = "form-status success";
            statusEl.textContent = data.message || "Đã gửi thông tin thành công! Chúng tôi sẽ liên hệ lại sớm nhất.";
          }
          form.reset();
          if (window.turnstile) {
            try { window.turnstile.reset(); } catch {}
          }
        } else {
          throw new Error(data.error || "Không thể gửi biểu mẫu lúc này. Vui lòng gọi trực tiếp hotline 0973 397 206.");
        }
      } catch (err) {
        if (statusEl) {
          statusEl.className = "form-status error";
          statusEl.textContent = err.message || "Có lỗi xảy ra. Vui lòng thử lại hoặc gọi 0973 397 206.";
        }
      } finally {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = origText;
        }
      }
    });
  });
})();
