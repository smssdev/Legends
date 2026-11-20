import { useState } from "react";
import { createRoot } from "react-dom/client";

function Counter() {
  const [count, setCount] = useState(0);

  function addThreeWrong() {
    // Every handler sees the value of this render: count is 0 three times
    setCount(count + 1);
    setCount(count + 1);
    setCount(count + 1);
  }

  function addThree() {
    // An updater function receives the latest value
    setCount((c) => c + 1);
    setCount((c) => c + 1);
    setCount((c) => c + 1);
  }

  return (
    <div className="card">
      <p className="big">{count}</p>
      <div className="row">
        <button onClick={addThreeWrong}>+3 (wrong)</button>
        <button onClick={addThree}>+3 (right)</button>
        <button className="secondary" onClick={() => setCount(0)}>Reset</button>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Counter />);
