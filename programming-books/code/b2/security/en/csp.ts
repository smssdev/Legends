import { withLab } from "./lab";

// Served with a strict Content Security Policy
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
  for (const line of blocked) console.log("Blocked by CSP:", line);
  console.log("script ran?", state.hacked ? "YES" : "no");
  console.log("The app still works:", state.title);
});
