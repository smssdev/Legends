type User = { id: number; name: string };

// حارس نوع: إن أرجع true عاملت TypeScript القيمة كـ User
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    typeof value.id === "number" &&
    "name" in value &&
    typeof value.name === "string"
  );
}

function parseUser(json: string): User {
  const data: unknown = JSON.parse(json);
  if (!isUser(data)) throw new TypeError("أرسل الخادم مستخدماً بشكل خاطئ");
  return data;
}

console.log(parseUser('{"id": 1, "name": "سارة"}').name);
try {
  parseUser('{"id": "1", "fullName": "سارة"}');
} catch (error) {
  console.log((error as Error).message);
}
