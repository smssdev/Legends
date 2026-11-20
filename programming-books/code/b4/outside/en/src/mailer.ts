import nodemailer from "nodemailer";
import { config } from "./config.ts";
import { pool } from "./db.ts";

const transport = nodemailer.createTransport(config.smtpUrl);

// the mailer: send what the outbox holds, mark it sent
const { rows } = await pool.query<{
  id: number;
  recipient: string;
  subject: string;
  body: string;
}>(
  "SELECT id, recipient, subject, body FROM outbox WHERE sent_at IS NULL ORDER BY id LIMIT 50",
);
for (const mail of rows) {
  await transport.sendMail({
    from: "Bit Booking <bookings@bitbooking.example>",
    to: mail.recipient,
    subject: mail.subject,
    text: mail.body,
    headers: { "X-Outbox-Id": String(mail.id) },
  });
  await pool.query("UPDATE outbox SET sent_at = now() WHERE id = $1", [mail.id]);
  console.log(`sent ${mail.id} to ${mail.recipient}`);
}
await pool.end();
