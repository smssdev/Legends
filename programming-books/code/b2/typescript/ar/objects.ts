type User = {
  readonly id: number;
  name: string;
  email: string;
  phone?: string; // اختياري: نص أو undefined
  roles: readonly string[];
};

const user: User = { id: 7, name: "سارة", email: "sara@example.com", roles: ["admin"] };

user.name = "هدى";
user.id = 8;
user.roles.push("editor");
console.log(user.phone.length);
