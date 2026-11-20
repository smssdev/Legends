class NotFoundError extends Error {
  constructor(what, options) {
    super(`${what} was not found`, options);
    this.name = "NotFoundError";
  }
}

const users = new Map([[1, "Sara"]]);

function findUser(id) {
  if (!users.has(id)) throw new NotFoundError(`User #${id}`);
  return users.get(id);
}

function loadProfile(id) {
  try {
    return findUser(id);
  } catch (error) {
    throw new Error("Could not load the profile", { cause: error }); // keep the original error as the cause
  }
}

try {
  loadProfile(7);
} catch (error) {
  console.log(error.message);
  console.log("Because:", error.cause.name, "-", error.cause.message);
  console.log(error.cause instanceof NotFoundError);
}
