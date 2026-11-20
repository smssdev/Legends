import { freeSlots } from "@/lib/bookings";

// الدالة نفسها خلف باب ثانٍ: الواجهة البرمجية العامة من الفصل 2
export async function GET(request: Request) {
  const query = new URL(request.url).searchParams;
  const staffId = Number(query.get("staff_id"));
  const date = query.get("date") ?? "";
  if (
    !Number.isInteger(staffId) ||
    staffId < 1 ||
    !/^\d{4}-\d{2}-\d{2}$/.test(date)
  ) {
    const problem = { title: "طلب غير صالح", status: 422 };
    return Response.json(problem, {
      status: 422,
      headers: { "content-type": "application/problem+json" },
    });
  }
  return Response.json({ data: await freeSlots(staffId, date) });
}
