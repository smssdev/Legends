type User = { id: number; name: string };

// A type guard: if it returns true, TypeScript treats value as a User
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
  if (!isUser(data)) throw new TypeError("The server sent a user in the wrong shape");
  return data;
}

console.log(parseUser('{"id": 1, "name": "Sara"}').name);
try {
  parseUser('{"id": "1", "fullName": "Sara"}');
} catch (error) {
  console.log((error as Error).message);
}
