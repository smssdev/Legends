const output = document.querySelector("#output");
const addButton = document.querySelector("#add");
const resetButton = document.querySelector("#reset");

let count = 0;

function show() {
  output.textContent = `ضغطت ${count} مرات`;
}

addButton.addEventListener("click", () => {
  count++;
  show();
});

resetButton.addEventListener("click", () => {
  count = 0;
  show();
});
