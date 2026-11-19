import { effectScope } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useStopwatch } from "./useStopwatch";

afterEach(() => vi.useRealTimers());

describe("useStopwatch", () => {
  it("يعدّ الثواني أثناء العمل فقط", () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const watch = scope.run(() => useStopwatch())!;
    watch.start();
    vi.advanceTimersByTime(3000);
    watch.stop();
    vi.advanceTimersByTime(5000);
    expect(watch.seconds.value).toBe(3);
    scope.stop();
  });

  it("التصفير يوقف ويعود إلى الصفر", () => {
    vi.useFakeTimers();
    const scope = effectScope();
    const watch = scope.run(() => useStopwatch())!;
    watch.start();
    vi.advanceTimersByTime(2000);
    watch.reset();
    expect(watch.seconds.value).toBe(0);
    expect(watch.running.value).toBe(false);
    scope.stop();
  });
});
