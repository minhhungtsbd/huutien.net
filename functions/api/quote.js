import { escapeHtml, sendSmtpEmail, verifyTurnstile } from "../_lib/smtp.js";

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

export async function onRequestPost({ request, env }) {
  try {
    const data = await request.json().catch(() => null);
    if (!data || typeof data !== "object") {
      return json({ ok: false, error: "Dữ liệu gửi lên không hợp lệ." }, 400);
    }

    if (data.website_hp) {
      return json({ ok: true, message: "Đã nhận yêu cầu." });
    }

    const hoTen = String(data.ho_ten || "").trim();
    const dienThoai = String(data.dien_thoai || "").trim();
    const email = String(data.email || "").trim();

    if (!hoTen || !dienThoai || !email) {
      return json({ ok: false, error: "Vui lòng nhập đầy đủ Họ tên, Điện thoại và Email." }, 400);
    }

    const ip = request.headers.get("CF-Connecting-IP") || "";
    const ts = await verifyTurnstile(data["cf-turnstile-response"], ip, env.TURNSTILE_SECRET_KEY);
    if (!ts.ok) {
      return json({ ok: false, error: ts.error }, 400);
    }

    const rows = [
      ["Họ tên", hoTen],
      ["Điện thoại", dienThoai],
      ["Email", email],
      ["Địa chỉ công trình", data.dia_chi || ""],
      ["Tên công trình", data.ten_cong_trinh || ""],
      ["Loại công trình", data.loai_cong_trinh || ""],
      ["Loại cửa / Hạng mục", data.loai_cua || ""],
      ["Số lượng cửa đi", data.so_luong_cua_di || ""],
      ["Kích thước cửa đi", data.kich_thuoc_cua_di || ""],
      ["Số lượng cửa sổ", data.so_luong_cua_so || ""],
      ["Kích thước cửa sổ", data.kich_thuoc_cua_so || ""],
      ["Ghi chú thêm", data.ghi_chu || ""],
    ];

    const trHtml = rows
      .map(
        ([label, val]) =>
          `<tr><td style="padding:8px;border:1px solid #dce5f0;font-weight:bold;width:190px">${escapeHtml(label)}</td><td style="padding:8px;border:1px solid #dce5f0;white-space:pre-line">${escapeHtml(String(val || "—"))}</td></tr>`
      )
      .join("");

    const htmlBody = `
      <div style="font-family:Arial,sans-serif;max-width:640px;margin:0 auto;color:#162231">
        <h2 style="color:#0b4ea2;border-bottom:2px solid #f5b400;padding-bottom:8px">Yêu cầu báo giá mới từ huutien.net</h2>
        <table style="width:100%;border-collapse:collapse;margin-top:12px">${trHtml}</table>
        <p style="font-size:12px;color:#64748b;margin-top:16px">Gửi lúc ${new Date().toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })} · IP: ${escapeHtml(ip)}</p>
      </div>
    `;

    await sendSmtpEmail(env, {
      subject: `[Báo giá huutien.net] ${hoTen} - ${dienThoai}`,
      htmlBody,
      replyTo: email,
    });

    return json({
      ok: true,
      message: "Đã gửi yêu cầu báo giá thành công! Mr. Tiến sẽ xem thông số và phản hồi bạn sớm nhất.",
    });
  } catch (err) {
    console.error("Quote form SMTP error:", err);
    return json(
      {
        ok: false,
        error: "Không thể gửi yêu cầu lúc này. Vui lòng gọi trực tiếp Mr. Tiến: 0973 397 206.",
      },
      500
    );
  }
}
