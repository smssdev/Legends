import { expect, it, vi } from "vitest";
import { debounce } from "./debounce";

it("calls the function once, after the user stops typing", () => {
  vi.useFakeTimers(); // the test controls the clock: no real waiting
  const search = vi.fn(); // a fake function that records its calls
  const debounced = debounce(search, 300);

  debounced("b");
  debounced("bi");
  debounced("bit");
  expect(search).not.toHaveBeenCalled();

  vi.advanceTimersByTime(300);
  expect(search).toHaveBeenCalledTimes(1);
  expect(search).toHaveBeenCalledWith("bit");
  vi.useRealTimers();
});
