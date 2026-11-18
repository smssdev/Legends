type User = {
  readonly id: number;
  name: string;
  email: string;
  phone?: string; // optional: string or undefined
  roles: readonly string[];
};

const user: User = { id: 7, name: "Sara", email: "sara@example.com", roles: ["admin"] };

user.name = "Huda";
user.id = 8;
user.roles.push("editor");
console.log(user.phone.length);
