import { signIn } from "@/lib/auth";
import { problem } from "@/lib/http";

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({}));
  const token = await signIn(
    String(body.email ?? "").slice(0, 254),
    String(body.password ?? "").slice(0, 128),
  );
  if (!token) return problem(401, "البريد أو كلمة المرور خطأ.");
  return Response.json({ token });
}
