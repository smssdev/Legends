function getCity(user) {
  return user.address.city;
}

function welcome(user) {
  return `Hello from ${getCity(user)}!`;
}

console.log(welcome({ name: "Sara" }));
