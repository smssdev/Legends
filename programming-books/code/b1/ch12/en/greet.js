const form = document.querySelector("#greet");
const input = document.querySelector("#name");
const output = document.querySelector("#output");

form.addEventListener("submit", (event) => {
  event.preventDefault();

  const name = input.value.trim();
  if (name === "") {
    output.textContent = "Please type your name.";
    return;
  }
  output.textContent = `Hello, ${name}! Welcome to the web.`;
  input.value = "";
});
