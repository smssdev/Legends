const message = document.querySelector("#message");
const left = document.querySelector("#left");
const limit = 120;

message.addEventListener("input", () => {
  const remaining = limit - message.value.length;
  left.textContent = remaining;
  left.classList.toggle("low", remaining < 20);
});
