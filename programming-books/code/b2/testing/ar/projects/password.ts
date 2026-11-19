export type Strength = "weak" | "okay" | "strong";

export function strength(password: string): Strength {
  let points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (/\d/.test(password)) points++;
  if (/[A-Z]/.test(password)) points++;
  if (points <= 1) return "weak";
  if (points <= 3) return "okay";
  return "strong";
}
