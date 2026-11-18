const button = document.querySelector("#theme");

button.addEventListener("click", () => {
  document.body.classList.toggle("dark");

  const isDark = document.body.classList.contains("dark");
  button.textContent = isDark ? "Switch to day" : "Switch to night";
});
