const questions = [
  { text: "أي لغة تعطي الصفحة بنيتها؟", options: ["CSS", "HTML", "JSON"], answer: 1 },
  { text: "أي دالة تجد عنصراً واحداً في الصفحة؟", options: ["querySelector", "console.log", "JSON.parse"], answer: 0 },
  { text: "أي حدث يقع حين يُضغط زر؟", options: ["input", "submit", "click"], answer: 2 },
];

const number = document.querySelector("#number");
const question = document.querySelector("#question");
const options = document.querySelector("#options");
const feedback = document.querySelector("#feedback");

let current = 0;
let points = 0;

function show() {
  const q = questions[current];
  number.textContent = `السؤال ${current + 1} من ${questions.length}`;
  question.textContent = q.text;
  options.replaceChildren();

  q.options.forEach((option, index) => {
    const button = document.createElement("button");
    button.textContent = option;
    button.addEventListener("click", () => choose(index));
    options.append(button);
  });
}

function choose(index) {
  const q = questions[current];
  if (index === q.answer) {
    points++;
    feedback.textContent = "إجابة صحيحة!";
    feedback.className = "right";
  } else {
    feedback.textContent = `ليس تماماً. الإجابة هي ${q.options[q.answer]}`;
    feedback.className = "wrong";
  }

  current++;
  if (current < questions.length) {
    show();
  } else {
    finish();
  }
}

function finish() {
  number.textContent = "";
  options.replaceChildren();
  question.textContent = `نتيجتك: ${points} من ${questions.length}`;

  const again = document.createElement("button");
  again.textContent = "العب مرة أخرى";
  again.addEventListener("click", () => {
    current = 0;
    points = 0;
    feedback.textContent = "";
    again.remove();
    show();
  });
  options.append(again);
}

show();
