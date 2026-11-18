const order = { id: 501, items: ["book", "mug"], paid: false };

const text = JSON.stringify(order);
console.log(text);
console.log(typeof text);

const back = JSON.parse('{"id":502,"items":["sticker"],"paid":true}');
console.log(back.items[0], back.paid);
