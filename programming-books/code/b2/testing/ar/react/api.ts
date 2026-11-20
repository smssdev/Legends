// خادم وهمي: بلا شبكة، والردود نفسها دائماً
export async function signIn(email: string, password: string): Promise<{ name: string }> {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "سارة" };
  throw new Error("البريد أو كلمة المرور غير صحيحة.");
}
