import { AuthError } from "./auth";

export function problem(status: number, title: string) {
  return Response.json(
    { title, status },
    { status, headers: { "content-type": "application/problem+json" } },
  );
}

export function authProblem(error: unknown) {
  if (!(error instanceof AuthError)) throw error;
  return problem(
    error.status,
    error.status === 401 ? "Not signed in" : "Not allowed",
  );
}
