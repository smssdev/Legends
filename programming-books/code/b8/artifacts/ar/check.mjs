import {chromium} from "playwright";
import path from "node:path";

// اختبر الـ artifact في متصفح حقيقي: اكتب فاتورة فيها قروش، واقرأ
// النتيجة.
export async function check(file) {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(`file://${path.resolve(file)}`);
  await page.fill("#bill", "85.50");
  await page.fill("#tip", "10");
  const tip = await page.textContent("#tip-amount");
  const total = await page.textContent("#total");
  await browser.close();
  const ok = tip === "8.55" && total === "94.05";
  const failure = "فاتورة 85.50 بنسبة 10% أعطت بقشيشاً $tip وإجمالياً $total؛ والمتوقع 8.55 و94.05".replace("$tip", tip).replace("$total", total);
  return {ok, failure: ok ? "" : failure};
}

if (process.argv[1].endsWith("check.mjs")) {
  const {ok, failure} = await check(process.argv[2]);
  console.log(ok ? `PASS ${process.argv[2]}` : `FAIL ${process.argv[2]}: ${failure}`);
}
