import { cloneElement, isValidElement, type ReactElement } from "react";

type FieldProps = {
  id: string;
  label: string;
  error?: string;
  children: ReactElement<Record<string, unknown>>;
};

// One place for the label, the error and the accessibility links between them
export function Field({ id, label, error, children }: FieldProps) {
  const errorId = `${id}-error`;
  const input = isValidElement(children)
    ? cloneElement(children, {
        "aria-invalid": error ? true : undefined,
        "aria-describedby": error ? errorId : undefined,
      })
    : children;
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {input}
      {error && (
        <p className="error" id={errorId}>
          {error}
        </p>
      )}
    </div>
  );
}
