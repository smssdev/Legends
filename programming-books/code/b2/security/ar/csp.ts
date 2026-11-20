import { withLab } from "./lab";

// تُقدَّم بسياسة أمان محتوى صارمة
const policy = "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'";

await withLab({ "Content-Security-Policy": policy }, async (page, base) => {
  const blocked: string[] = [];
  page.on("console", (m) => {
    if (m.text().includes("Content Security Policy")) blocked.push(m.text().slice(0, 70) + "…");
  });
  await page.goto(base + "csp.html");
  await page.waitForTimeout(200);
  const state = await page.evaluate(
    () => ({ hacked: (window as { hacked?: boolean }).hacked === true, title: document.querySelector("#title")!.textContent }),
    null,
  );
  for (const line of blocked) console.log("منعته CSP:", line);
  console.log("عمل السكربت؟", state.hacked ? "نعم" : "لا");
  console.log("التطبيق ما زال يعمل:", state.title);
});
