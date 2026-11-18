const list = ["bread", "milk"];

const toAdd = ["eggs", "bread", "tomatoes"];
for (const item of toAdd) {
  if (list.includes(item)) {
    console.log(`${item} is already on the list`);
  } else {
    list.push(item);
  }
}

console.log("Shopping list:");
for (let i = 0; i < list.length; i++) {
  console.log(`${i + 1}. ${list[i]}`);
}
