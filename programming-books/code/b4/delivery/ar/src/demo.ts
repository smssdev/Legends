import createClient from "openapi-fetch";
import type { paths } from "./api.d.ts";

// عميل أنواعه من العقد: المسارات والمعاملات والأجسام والإجابات
const api = createClient<paths>({ baseUrl: "http://localhost:3000" });

const slots = await api.GET("/slots", {
  params: { query: { staff_id: 1, date: "2026-12-01" } },
});
const free = slots.data?.data ?? [];
console.log(
  "أول المواعيد المتاحة:",
  free.slice(0, 3).map((s) => s.starts_at),
);

const body = {
  staff_id: 1,
  starts_at: free[0]!.starts_at,
  email: "sara@example.com",
};
const first = await api.POST("/bookings", { body });
console.log(
  "الحجز الأول:",
  first.response.status,
  first.data?.id,
  first.data?.status,
);

const again = await api.POST("/bookings", {
  body: { ...body, email: "karim@example.com" },
});
console.log("الموعد نفسه ثانية:", again.response.status, again.error?.title);
