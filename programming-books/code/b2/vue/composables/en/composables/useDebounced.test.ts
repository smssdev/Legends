import { nextTick, ref } from "vue";
import { expect, it, vi } from "vitest";
import { useDebounced } from "./useDebounced";

it("waits until the value has stopped changing", async () => {
  vi.useFakeTimers();
  const text = ref("b");
  const slow = useDebounced(text, 300);
  for (const next of ["bi", "bit"]) {
    text.value = next;
    await nextTick();
    vi.advanceTimersByTime(100);
  }
  expect(slow.value).toBe("b");
  vi.advanceTimersByTime(300);
  expect(slow.value).toBe("bit");
  vi.useRealTimers();
});
