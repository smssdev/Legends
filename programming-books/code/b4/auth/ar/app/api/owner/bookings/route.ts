import { requireUser } from "@/lib/auth";
import { authProblem } from "@/lib/http";
import { bookingsFor } from "@/lib/owner";

// الفحص نفسه والدالة المحصورة نفسها، لتطبيق الجوال
export async function GET(request: Request) {
  try {
    const user = await requireUser(["owner", "staff"], request);
    return Response.json({ data: await bookingsFor(user) });
  } catch (error) {
    return authProblem(error);
  }
}
