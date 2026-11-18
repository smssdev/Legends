import type { ComponentProps } from "react";

type Variant = "primary" | "secondary" | "danger" | "ghost";
type Size = "sm" | "md" | "lg";

type ButtonProps = ComponentProps<"button"> & {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
};

// Every native button prop (type, disabled, onClick, aria-…) still works
export function Button({ variant = "primary", size = "md", loading = false, className, children, disabled, ...rest }: ButtonProps) {
  const classes = ["btn", `btn-${variant}`, `btn-${size}`, className].filter(Boolean).join(" ");
  return (
    <button type="button" className={classes} disabled={disabled || loading} aria-busy={loading || undefined} {...rest}>
      {loading && <span className="spinner" aria-hidden="true" />}
      {children}
    </button>
  );
}
