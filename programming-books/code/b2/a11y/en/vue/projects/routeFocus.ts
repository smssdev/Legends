import { nextTick, ref } from "vue";
import type { Router } from "vue-router";

// After every navigation: update the title, move the focus to the new h1, and announce the page
export const announcement = ref("");

export function routeFocus(router: Router, appName: string) {
  router.afterEach(async (_to, from) => {
    if (from.matched.length === 0) return; // the first page load is announced by the browser itself
    await nextTick(); // wait for the new page to be drawn
    const heading = document.querySelector<HTMLElement>("main h1");
    if (!heading) return;
    document.title = `${heading.textContent} · ${appName}`;
    heading.tabIndex = -1;
    heading.focus();
    announcement.value = heading.textContent ?? "";
  });
}
