function getCity(user) {
  return user.address.city;
}

function welcome(user) {
  return `أهلاً من ${getCity(user)}!`;
}

console.log(welcome({ name: "سارة" }));
