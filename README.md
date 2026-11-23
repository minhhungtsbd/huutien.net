# huutien.net – Cửa Cổng Nhôm Sắt Hữu Tiến (Quy Nhơn)

Website tĩnh tốc độ cao chuyển đổi hoàn chỉnh từ WordPress sang **Cloudflare Pages + Cloudflare Pages Functions (Worker)**, giữ nguyên toàn bộ cấu trúc đường dẫn SEO, hình ảnh, bài viết, trang sản phẩm, công trình và nâng cấp giao diện hiện đại, chuẩn mobile.

## Cấu trúc dự án

- `content/site.json`: Cấu hình thương hiệu, hotline, địa chỉ, slide trang chủ, quy trình và đánh giá Google Maps.
- `content/data.json`: Toàn bộ dữ liệu 18 trang, 11 bài viết và 5 công trình đã chuẩn hóa.
- `public/media/`: Toàn bộ hình ảnh nội dung đã tải về cục bộ (không phụ thuộc hosting WordPress cũ).
- `public/assets/style.css` & `public/assets/site.js`: Giao diện nâng cấp, tìm kiếm tiếng Việt không dấu, lọc công trình, lightbox xem ảnh lớn và gửi form AJAX.
- `scripts/build.mjs`: Script build tĩnh bằng Node.js thuần (không cần cài `node_modules`), xuất ra `dist/`.
- `scripts/build.ps1`: Script build tương đương cho Windows PowerShell.
- `functions/api/contact.js`, `functions/api/quote.js`, `functions/_lib/smtp.js`: Cloudflare Pages Functions xử lý 2 form **Liên hệ** và **Yêu cầu báo giá**, gửi email trực tiếp qua **SMTP** bằng `cloudflare:sockets` (hỗ trợ TLS port 465 & STARTTLS port 587) và xác thực **Cloudflare Turnstile**.

## Triển khai lên Cloudflare Pages (Git Integration)

1. Vào **Cloudflare Dashboard → Workers & Pages → Create → Pages → Connect to Git**.
2. Chọn repository `minhhungtsbd/huutien.net`.
3. Thiết lập cấu hình build:

| Thiết lập | Giá trị |
|---|---|
| Production branch | `main` |
| Framework preset | `None` |
| Build command | `npm run build` |
| Build output directory | `dist` |
| Root directory | *(Để trống)* |

4. Thêm các **Environment variables** (Settings → Environment variables → Production & Preview) cho máy chủ SMTP của bạn:

| Biến | Mô tả | Ví dụ |
|---|---|---|
| `SMTP_HOST` | Máy chủ SMTP | `smtp.gmail.com` hoặc `mail.domain.com` |
| `SMTP_PORT` | Cổng SMTP | `465` (TLS) hoặc `587` (STARTTLS) |
| `SMTP_SECURE` | Chế độ bảo mật (`tls` / `starttls` / `none`) | `tls` |
| `SMTP_USER` | Tài khoản đăng nhập SMTP | `noreply@domain.com` |
| `SMTP_PASS` | Mật khẩu SMTP *(chọn Encrypt)* | `••••••••` |
| `SMTP_FROM` | Địa chỉ gửi đi | `Nhôm Sắt Hữu Tiến <noreply@domain.com>` |
| `SMTP_TO` | Email nhận thông báo (ngăn cách dấu phẩy nếu nhiều) | `huutien9206@gmail.com` |
| `TURNSTILE_SECRET_KEY` | *(Tùy chọn)* Secret Key của Cloudflare Turnstile *(chọn Encrypt)* | `0x4AAAAA...` |

5. Sau khi deploy xong, thêm Custom Domain `huutien.net` (và `www.huutien.net`) trong tab **Custom domains** của Cloudflare Pages.

> **Lưu ý về cổng SMTP trên Cloudflare Workers:** Cloudflare Workers hỗ trợ kết nối TCP ra ngoài qua `cloudflare:sockets` trên các cổng tiêu chuẩn như **465** (TLS) và **587** (STARTTLS). Cổng 25 thường bị chặn để chống spam.
