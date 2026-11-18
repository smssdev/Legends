import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function Timer() {
  const [running, setRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id); // Without the cleanup, every render would start another interval
  }, [running]);

  useEffect(() => {
    document.title = `${seconds} seconds · Timer`;
  }, [seconds]);

  return (
    <div className="card">
      <p className="big">
        {seconds} seconds
      </p>
      <button onClick={() => setRunning(!running)}>{running ? "Stop" : "Start"}</button>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Timer />);
