import type { ReactNode } from "react";

type Tone = "info" | "success" | "warning" | "danger";

const ICONS: Record<Tone, string> = { info: "ℹ", success: "✓", warning: "!", danger: "✕" };

export function Alert({ tone = "info", children }: { tone?: Tone; children: ReactNode }) {
  // Errors interrupt (alert); everything else waits for a pause (status)
  const role = tone === "danger" ? "alert" : "status";
  return (
    <div className={`alert alert-${tone}`} role={role}>
      <span aria-hidden="true">{ICONS[tone]}</span>
      <span>{children}</span>
    </div>
  );
}
