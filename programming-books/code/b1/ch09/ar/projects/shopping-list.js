const list = ["خبز", "حليب"];

const toAdd = ["بيض", "خبز", "طماطم"];
for (const item of toAdd) {
  if (list.includes(item)) {
    console.log(`${item} موجود في القائمة أصلاً`);
  } else {
    list.push(item);
  }
}

console.log("قائمة التسوق:");
for (let i = 0; i < list.length; i++) {
  console.log(`${i + 1}. ${list[i]}`);
}
