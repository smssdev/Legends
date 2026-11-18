const firstName = "سارة";
const visits = 3;

function welcome(person, count) {
  const message = `مرحباً بعودتك يا ${person}! زيارتك #${count}`;
  return message;
}

console.log(welcome(firstName, visits));
