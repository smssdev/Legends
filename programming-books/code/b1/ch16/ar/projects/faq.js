const buttons = document.querySelectorAll(".faq button");

for (const button of buttons) {
  button.addEventListener("click", () => {
    const open = button.getAttribute("aria-expanded") === "true";
    const answer = document.querySelector("#" + button.getAttribute("aria-controls"));

    button.setAttribute("aria-expanded", String(!open));
    answer.hidden = open;
  });
}
