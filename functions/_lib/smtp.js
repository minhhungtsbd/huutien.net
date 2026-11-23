import { connect } from "cloudflare:sockets";

const encoder = new TextEncoder();
const decoder = new TextDecoder();

function toBase64Utf8(str) {
  const bytes = encoder.encode(str);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function encodeMimeHeader(str) {
  return `=?UTF-8?B?${toBase64Utf8(str)}?=`;
}

function escapeHtml(str = "") {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function extractEmail(addr = "") {
  const m = String(addr).match(/<([^>]+)>/);
  return (m ? m[1] : addr).trim();
}

function wrapBase64(b64) {
  return b64.replace(/.{1,76}/g, "$&\r\n").trimEnd();
}

class SmtpConn {
  constructor(socket) {
    this.socket = socket;
    this.reader = socket.readable.getReader();
    this.writer = socket.writable.getWriter();
    this.buf = "";
  }

  async readResponse() {
    let lines = [];
    while (true) {
      const nl = this.buf.indexOf("\r\n");
      if (nl !== -1) {
        const line = this.buf.slice(0, nl);
        this.buf = this.buf.slice(nl + 2);
        lines.push(line);
        // Final line of SMTP response has space after 3-digit code (e.g. "250 OK")
        if (/^\d{3} /.test(line)) {
          const code = Number(line.slice(0, 3));
          return { code, text: lines.join("\n") };
        }
        continue;
      }
      const { value, done } = await this.reader.read();
      if (done) {
        throw new Error(`SMTP connection closed unexpectedly (${lines.join(" | ")})`);
      }
      this.buf += decoder.decode(value, { stream: true });
    }
  }

  async send(cmd, expectedCodes) {
    await this.writer.write(encoder.encode(`${cmd}\r\n`));
    const res = await this.readResponse();
    if (expectedCodes && !expectedCodes.includes(res.code)) {
      throw new Error(`SMTP error (${res.code}): ${res.text}`);
    }
    return res;
  }

  async upgradeTls() {
    this.reader.releaseLock();
    this.writer.releaseLock();
    this.socket = this.socket.startTls();
    this.reader = this.socket.readable.getReader();
    this.writer = this.socket.writable.getWriter();
    this.buf = "";
  }

  async close() {
    try {
      await this.writer.write(encoder.encode("QUIT\r\n"));
    } catch {}
    try {
      await this.socket.close();
    } catch {}
  }
}

export async function verifyTurnstile(token, ip, secretKey) {
  if (!secretKey) return { ok: true, skipped: true };
  if (!token) return { ok: false, error: "Vui lòng xác nhận bạn không phải robot (Turnstile)." };

  const form = new URLSearchParams();
  form.set("secret", secretKey);
  form.set("response", token);
  if (ip) form.set("remoteip", ip);

  const resp = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body: form,
  });
  const data = await resp.json().catch(() => ({}));
  if (!data.success) {
    return { ok: false, error: "Xác thực chống spam thất bại. Vui lòng thử lại." };
  }
  return { ok: true };
}

export async function sendSmtpEmail(env, { subject, htmlBody, replyTo }) {
  const host = (env.SMTP_HOST || "").trim();
  const port = Number(env.SMTP_PORT || 465);
  const user = (env.SMTP_USER || "").trim();
  const pass = env.SMTP_PASS || "";
  const from = (env.SMTP_FROM || user || "no-reply@huutien.net").trim();
  const toRaw = (env.SMTP_TO || "huutien9206@gmail.com").trim();
  const secureMode = (env.SMTP_SECURE || (port === 465 ? "tls" : port === 587 ? "starttls" : "none")).toLowerCase();

  if (!host) {
    throw new Error("Chưa cấu hình SMTP_HOST trên Cloudflare Pages Environment Variables.");
  }

  const secureTransport = secureMode === "tls" ? "on" : secureMode === "starttls" ? "starttls" : "off";
  const socket = connect({ hostname: host, port }, { secureTransport, allowHalfOpen: false });
  const conn = new SmtpConn(socket);

  try {
    const greet = await conn.readResponse();
    if (greet.code !== 220) throw new Error(`SMTP greeting failed (${greet.code}): ${greet.text}`);

    const ehloHost = "huutien.net";
    await conn.send(`EHLO ${ehloHost}`, [250]);

    if (secureMode === "starttls") {
      await conn.send("STARTTLS", [220]);
      await conn.upgradeTls();
      await conn.send(`EHLO ${ehloHost}`, [250]);
    }

    if (user && pass) {
      await conn.send("AUTH LOGIN", [334]);
      await conn.send(toBase64Utf8(user), [334]);
      await conn.send(toBase64Utf8(pass), [235]);
    }

    const fromAddr = extractEmail(from);
    const recipients = toRaw
      .split(",")
      .map((r) => extractEmail(r))
      .filter(Boolean);

    await conn.send(`MAIL FROM:<${fromAddr}>`, [250]);
    for (const rcpt of recipients) {
      await conn.send(`RCPT TO:<${rcpt}>`, [250, 251]);
    }

    await conn.send("DATA", [354]);

    const dateHdr = new Date().toUTCString();
    const msgId = `<${Date.now()}.${Math.random().toString(36).slice(2)}@huutien.net>`;
    const headers = [
      `From: ${from.includes("<") ? from : `${encodeMimeHeader("Nhôm Sắt Hữu Tiến")} <${fromAddr}>`}`,
      `To: ${recipients.join(", ")}`,
      replyTo ? `Reply-To: ${extractEmail(replyTo)}` : null,
      `Subject: ${encodeMimeHeader(subject)}`,
      `Date: ${dateHdr}`,
      `Message-ID: ${msgId}`,
      "MIME-Version: 1.0",
      'Content-Type: text/html; charset="UTF-8"',
      "Content-Transfer-Encoding: base64",
    ].filter(Boolean);

    const payload = `${headers.join("\r\n")}\r\n\r\n${wrapBase64(toBase64Utf8(htmlBody))}\r\n.`;
    await conn.send(payload, [250]);
  } finally {
    await conn.close();
  }
}

export { escapeHtml };
