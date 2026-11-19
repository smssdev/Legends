// A fake server: no network, always the same answers
export async function signIn(email: string, password: string): Promise<{ name: string }> {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "Sara" };
  throw new Error("Wrong email or password.");
}
