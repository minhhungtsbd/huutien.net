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

    // Honeypot anti-spam check
    if (data.website_hp) {
      return json({ ok: true, message: "Đã nhận thông tin." });
    }

    const name = String(data.name || "").trim();
    const phone = String(data.phone || "").trim();
    const email = String(data.email || "").trim();
    const message = String(data.message || "").trim();

    if (!name || !phone || !message) {
      return json({ ok: false, error: "Vui lòng nhập đầy đủ Họ tên, Số điện thoại và Nội dung." }, 400);
    }

    const ip = request.headers.get("CF-Connecting-IP") || "";
    const ts = await verifyTurnstile(data["cf-turnstile-response"], ip, env.TURNSTILE_SECRET_KEY);
    if (!ts.ok) {
      return json({ ok: false, error: ts.error }, 400);
    }

    const htmlBody = `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#162231">
        <h2 style="color:#0b4ea2;border-bottom:2px solid #f5b400;padding-bottom:8px">Liên hệ mới từ huutien.net</h2>
        <table style="width:100%;border-collapse:collapse;margin-top:12px">
          <tr><td style="padding:8px;border:1px solid #dce5f0;font-weight:bold;width:150px">Họ và tên</td><td style="padding:8px;border:1px solid #dce5f0">${escapeHtml(name)}</td></tr>
          <tr><td style="padding:8px;border:1px solid #dce5f0;font-weight:bold">Số điện thoại</td><td style="padding:8px;border:1px solid #dce5f0"><a href="tel:${escapeHtml(phone)}">${escapeHtml(phone)}</a></td></tr>
          <tr><td style="padding:8px;border:1px solid #dce5f0;font-weight:bold">Email</td><td style="padding:8px;border:1px solid #dce5f0">${escapeHtml(email || "(Không cung cấp)")}</td></tr>
          <tr><td style="padding:8px;border:1px solid #dce5f0;font-weight:bold">Nội dung</td><td style="padding:8px;border:1px solid #dce5f0;white-space:pre-line">${escapeHtml(message)}</td></tr>
        </table>
        <p style="font-size:12px;color:#64748b;margin-top:16px">Gửi lúc ${new Date().toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })} · IP: ${escapeHtml(ip)}</p>
      </div>
    `;

    await sendSmtpEmail(env, {
      subject: `[Liên hệ huutien.net] ${name} - ${phone}`,
      htmlBody,
      replyTo: email || undefined,
    });

    return json({
      ok: true,
      message: "Cảm ơn bạn đã liên hệ! Nhôm Sắt Hữu Tiến đã nhận thông tin và sẽ phản hồi sớm nhất.",
    });
  } catch (err) {
    console.error("Contact form SMTP error:", err);
    return json(
      {
        ok: false,
        error: "Không thể gửi email lúc này. Vui lòng gọi trực tiếp Mr. Tiến: 0973 397 206.",
      },
      500
    );
  }
}
