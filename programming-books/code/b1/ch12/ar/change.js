// 1. تغيير النص
const title = document.querySelector("h1");
title.textContent = "عنوان جديد كتبته JavaScript!";

// 2. إضافة صنف (وCSS تتولى التنسيق)
document.querySelector(".note").classList.add("highlight");

// 3. إنشاء عنصر جديد وإضافته إلى الصفحة
const item = document.createElement("li");
item.textContent = "JavaScript";
document.querySelector("#skills").append(item);
