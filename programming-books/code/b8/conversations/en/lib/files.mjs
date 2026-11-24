import fs from "node:fs";
import path from "node:path";

const TYPES = {
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".gif": "image/gif", ".webp": "image/webp",
};

// A file on disk as a content block: images by extension, PDFs as
// documents.
export function block(file, title) {
  const data = fs.readFileSync(file).toString("base64");
  if (file.endsWith(".pdf")) {
    const source = {type: "base64", media_type: "application/pdf", data};
    return {type: "document", source, title};
  }
  const source = {type: "base64", media_type: TYPES[path.extname(file)], data};
  return {type: "image", source};
}

// The text of a response, whatever other blocks it has.
export function text(response) {
  const blocks = response.content.filter((b) => b.type === "text");
  return blocks.map((b) => b.text).join("");
}
