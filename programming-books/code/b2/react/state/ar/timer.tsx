import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function Timer() {
  const [running, setRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id); // دون التنظيف سيبدأ كل رسم مؤقتاً آخر
  }, [running]);

  useEffect(() => {
    document.title = `${seconds} ثانية · المؤقت`;
  }, [seconds]);

  return (
    <div className="card">
      <p className="big">
        {seconds} ثانية
      </p>
      <button onClick={() => setRunning(!running)}>{running ? "أوقف" : "ابدأ"}</button>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Timer />);
