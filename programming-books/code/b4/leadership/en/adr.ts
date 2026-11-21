import { readFileSync, readdirSync, writeFileSync } from "node:fs";

const dir = "docs/adr";
const files = readdirSync(dir)
  .filter((f) => /^\d{4}-.*\.md$/.test(f))
  .sort();

// each record starts with its title, then a Status line
function read(file: string) {
  const text = readFileSync(`${dir}/${file}`, "utf8");
  const title = text.split("\n")[0]!.replace(/^# /, "");
  const status = /^Status: (.+)$/m.exec(text)?.[1] ?? "?";
  return { number: file.slice(0, 4), title, status };
}

const [command, ...words] = process.argv.slice(2);
if (command === "new") {
  // the next number: records are superseded, never deleted or renumbered
  const number = String(files.length + 1).padStart(4, "0");
  const title = words.join(" ");
  const slug = `${number}-${title.toLowerCase().replaceAll(" ", "-")}`;
  // the template keeps every record short and in the same shape
  const template = readFileSync(`${dir}/template.md`, "utf8");
  writeFileSync(
    `${dir}/${slug}.md`,
    template.replace("TITLE", `${number}. ${title}`),
  );
  console.log(`${dir}/${slug}.md`);
} else {
  for (const file of files) {
    const { number, title, status } = read(file);
    // a superseded record stays: it explains what the team believed, and when
    console.log(`${number}  ${status.padEnd(26)} ${title.replace(/^\d+\. /, "")}`);
  }
}
