import fs from "node:fs";

// قسّم المستند الطويل عند عناوينه، ليكون كل جزء عن شيء واحد.
export function chunks(markdown) {
  return markdown
    .split(/^(?=# )/m)
    .map((part) => part.trim())
    .filter(Boolean)
    .map((part) => {
      const [title, ...body] = part.split("\n");
      return {id: title.replace(/^# /, "").toLowerCase(), text: body.join(" ")};
    });
}

for (const {id, text} of chunks(fs.readFileSync("data/handbook.md", "utf8"))) {
  console.log(`[${id}] ${text}`);
}
