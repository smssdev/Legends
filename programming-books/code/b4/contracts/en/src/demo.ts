import createClient from "openapi-fetch";
import type { paths } from "./api.d.ts";

// a client typed by the contract: paths, parameters, bodies and answers
const api = createClient<paths>({ baseUrl: "http://localhost:3000" });

const slots = await api.GET("/slots", {
  params: { query: { staff_id: 1, date: "2026-12-01" } },
});
const free = slots.data?.data ?? [];
console.log(
  "first free slots:",
  free.slice(0, 3).map((s) => s.starts_at),
);

const body = {
  staff_id: 1,
  starts_at: free[0]!.starts_at,
  email: "sara@example.com",
};
const first = await api.POST("/bookings", { body });
console.log(
  "first booking:",
  first.response.status,
  first.data?.id,
  first.data?.status,
);

const again = await api.POST("/bookings", {
  body: { ...body, email: "karim@example.com" },
});
console.log("same slot again:", again.response.status, again.error?.title);
