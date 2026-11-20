import { useState } from "react";

type SwitchProps = {
  label: string;
  checked?: boolean; // controlled: the parent owns the value
  defaultChecked?: boolean; // uncontrolled: the switch owns it
  onChange?: (checked: boolean) => void;
};

export function Switch({ label, checked, defaultChecked = false, onChange }: SwitchProps) {
  const [inner, setInner] = useState(defaultChecked);
  const isControlled = checked !== undefined;
  const on = isControlled ? checked : inner;

  function toggle() {
    if (!isControlled) setInner(!on);
    onChange?.(!on);
  }

  return (
    <button type="button" role="switch" aria-checked={on} className="switch" onClick={toggle}>
      <span className="track" aria-hidden="true">
        <span className="thumb" />
      </span>
      {label}
    </button>
  );
}
