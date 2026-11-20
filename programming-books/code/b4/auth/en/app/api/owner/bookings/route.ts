import { requireUser } from "@/lib/auth";
import { authProblem } from "@/lib/http";
import { bookingsFor } from "@/lib/owner";

// the same check and the same scoped function, for the mobile app
export async function GET(request: Request) {
  try {
    const user = await requireUser(["owner", "staff"], request);
    return Response.json({ data: await bookingsFor(user) });
  } catch (error) {
    return authProblem(error);
  }
}
