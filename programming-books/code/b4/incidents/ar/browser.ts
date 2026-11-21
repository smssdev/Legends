import { flush, inject, tracer } from "./tracer.ts";

const { start, span, end } = tracer("web");
// يبدأ التتبع في المتصفح، حين ينقر الزبون
const click = start("click Book");
await span("fetch POST /bookings", click, async (s) => {
  // الترويسة نفسها التي مرّرها الكتاب الثالث بين الخدمات، الآن من المتصفح
  const answer = await fetch("http://localhost:4000/bookings", {
    method: "POST",
    headers: inject(s),
  });
  return answer.json();
});
end(click);
await flush();
console.log(click.traceId);
