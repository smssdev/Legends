const form = document.querySelector("#greet");
const input = document.querySelector("#name");
const output = document.querySelector("#output");

form.addEventListener("submit", (event) => {
  event.preventDefault();

  const name = input.value.trim();
  if (name === "") {
    output.textContent = "من فضلك اكتب اسمك.";
    return;
  }
  output.textContent = `أهلاً يا ${name}! مرحباً بك في الويب.`;
  input.value = "";
});
