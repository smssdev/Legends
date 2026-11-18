const questions = [
  { text: "Which language gives a page its structure?", options: ["CSS", "HTML", "JSON"], answer: 1 },
  { text: "Which method finds one element on the page?", options: ["querySelector", "console.log", "JSON.parse"], answer: 0 },
  { text: "Which event fires when a button is pressed?", options: ["input", "submit", "click"], answer: 2 },
];

const number = document.querySelector("#number");
const question = document.querySelector("#question");
const options = document.querySelector("#options");
const feedback = document.querySelector("#feedback");

let current = 0;
let points = 0;

function show() {
  const q = questions[current];
  number.textContent = `Question ${current + 1} / ${questions.length}`;
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
    feedback.textContent = "Correct!";
    feedback.className = "right";
  } else {
    feedback.textContent = `Not quite. The answer is ${q.options[q.answer]}.`;
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
  question.textContent = `Your score: ${points} / ${questions.length}`;

  const again = document.createElement("button");
  again.textContent = "Play again";
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
