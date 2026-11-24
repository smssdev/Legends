import Anthropic from "@anthropic-ai/sdk";
import fs from "node:fs";

const client = new Anthropic();

// صورة تقول إنها شيء آخر.
const data = fs.readFileSync("files/sales.png").toString("base64");
try {
  await client.messages.create({
    model: "claude-opus-5-5",
    max_tokens: 1000,
    messages: [{role: "user", content: [
      {type: "image", source: {type: "base64", media_type: "image/jpeg", data}},
      {type: "text", text: "ماذا يُظهر هذا الرسم؟ أعطِ الأرقام."},
    ]}],
  });
} catch (error) {
  const message = error.error?.error?.message;
  console.log(`${error.status} ${error.constructor.name}: ${message}`);
}
