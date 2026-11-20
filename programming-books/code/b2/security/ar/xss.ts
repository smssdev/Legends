import { withLab } from "./lab";

// What an attacker types into the comment box
const comment = `<img src="x" onerror="window.hacked = true"> كتاب جميل!`;

await withLab({}, async (page, base) => {
  for (const way of ["innerHTML", "textContent"] as const) {
    await page.goto(base + "comments.html");
    const result = await page.evaluate(
      async ({ way, comment }) => {
        const li = document.createElement("li");
        if (way === "innerHTML") li.innerHTML = comment; // dangerous
        else li.textContent = comment; // safe
        document.querySelector("#list")!.append(li);
        await new Promise((r) => setTimeout(r, 100)); // give the broken image time to fire onerror
        return { ran: (window as { hacked?: boolean }).hacked === true, html: li.innerHTML };
      },
      { way, comment },
    );
    console.log(`${way.padEnd(12)} عمل السكربت؟ ${result.ran ? "نعم" : "لا"}`);
  }
});
