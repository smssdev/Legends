// 1. Change text
const title = document.querySelector("h1");
title.textContent = "New title, set by JavaScript!";

// 2. Add a class (the CSS does the styling)
document.querySelector(".note").classList.add("highlight");

// 3. Create a new element and add it to the page
const item = document.createElement("li");
item.textContent = "JavaScript";
document.querySelector("#skills").append(item);
