import { readFileSync, readdirSync, writeFileSync } from "node:fs";

const dir = "docs/adr";
const files = readdirSync(dir)
  .filter((f) => /^\d{4}-.*\.md$/.test(f))
  .sort();

// يبدأ كل سجل بعنوانه، ثم سطر Status
function read(file: string) {
  const text = readFileSync(`${dir}/${file}`, "utf8");
  const title = text.split("\n")[0]!.replace(/^# /, "");
  const status = /^Status: (.+)$/m.exec(text)?.[1] ?? "?";
  return { number: file.slice(0, 4), title, status };
}

const [command, ...words] = process.argv.slice(2);
if (command === "new") {
  // الرقم التالي: السجلات تُستبدل، ولا تُحذف ولا يُعاد ترقيمها أبداً
  const number = String(files.length + 1).padStart(4, "0");
  const title = words.join(" ");
  const slug = `${number}-${title.toLowerCase().replaceAll(" ", "-")}`;
  // القالب يُبقي كل سجل قصيراً وعلى الشكل نفسه
  const template = readFileSync(`${dir}/template.md`, "utf8");
  writeFileSync(
    `${dir}/${slug}.md`,
    template.replace("TITLE", `${number}. ${title}`),
  );
  console.log(`${dir}/${slug}.md`);
} else {
  for (const file of files) {
    const { number, title, status } = read(file);
    // السجل المُستبدَل يبقى: يشرح ما اعتقده الفريق، ومتى
    console.log(`${number}  ${status.padEnd(26)} ${title.replace(/^\d+\. /, "")}`);
  }
}
