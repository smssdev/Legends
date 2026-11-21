import { flush, inject, tracer } from "./tracer.ts";

const { start, span, end } = tracer("web");
// the trace starts in the browser, when the customer clicks
const click = start("click Book");
await span("fetch POST /bookings", click, async (s) => {
  // the same header that Book 3 passed between services, now from the browser
  const answer = await fetch("http://localhost:4000/bookings", {
    method: "POST",
    headers: inject(s),
  });
  return answer.json();
});
end(click);
await flush();
console.log(click.traceId);
