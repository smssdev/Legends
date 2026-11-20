import { requireUser } from "@/lib/auth";
import { authProblem, problem } from "@/lib/http";
import { cancelBooking } from "@/lib/owner";

type Context = { params: Promise<{ id: string }> };

export async function POST(request: Request, { params }: Context) {
  try {
    const user = await requireUser(["owner"], request);
    const done = await cancelBooking(user, Number((await params).id));
    return done ? Response.json({ cancelled: true }) : problem(404, "Not found");
  } catch (error) {
    return authProblem(error);
  }
}
