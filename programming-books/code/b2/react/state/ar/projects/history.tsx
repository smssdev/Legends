import { useState } from "react";
import { createRoot } from "react-dom/client";

function StepCounter() {
  const [step, setStep] = useState(1);
  const [history, setHistory] = useState<number[]>([0]);
  const value = history.at(-1) ?? 0; // derived from the history

  function change(by: number) {
    setHistory((h) => [...h, (h.at(-1) ?? 0) + by]);
  }

  function undo() {
    setHistory((h) => (h.length > 1 ? h.slice(0, -1) : h));
  }

  return (
    <div className="card">
      <p className="big">{value}</p>
      <label htmlFor="step">الخطوة</label>
      <input id="step" type="number" min={1} value={step} onChange={(e) => setStep(Number(e.target.value) || 1)} />
      <div className="row" style={{ marginTop: 10 }}>
        <button onClick={() => change(-step)}>− {step}</button>
        <button onClick={() => change(step)}>+ {step}</button>
        <button className="secondary" onClick={undo} disabled={history.length === 1}>
          تراجع
        </button>
      </div>
      <p className="muted">
        السجل: {history.join(" ← ")}
      </p>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<StepCounter />);
