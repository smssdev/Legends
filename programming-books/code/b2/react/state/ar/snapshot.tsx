import { useState } from "react";
import { createRoot } from "react-dom/client";

function Counter() {
  const [count, setCount] = useState(0);

  function addThreeWrong() {
    // كل معالج يرى قيمة هذا الرسم: count is 0 three times
    setCount(count + 1);
    setCount(count + 1);
    setCount(count + 1);
  }

  function addThree() {
    // دالة التحديث تستقبل أحدث قيمة
    setCount((c) => c + 1);
    setCount((c) => c + 1);
    setCount((c) => c + 1);
  }

  return (
    <div className="card">
      <p className="big">{count}</p>
      <div className="row">
        <button onClick={addThreeWrong}>‎+3 (خطأ)</button>
        <button onClick={addThree}>‎+3 (صحيح)</button>
        <button className="secondary" onClick={() => setCount(0)}>صفّر</button>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Counter />);
