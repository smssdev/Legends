const firstName = "Sara";
const visits = 3;

function welcome(person, count) {
  const message = `Welcome back, ${person}! visit #${count}`;
  return message;
}

console.log(welcome(firstname, visits));
