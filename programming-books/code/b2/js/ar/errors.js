class NotFoundError extends Error {
  constructor(what, options) {
    super(`${what} غير موجود`, options);
    this.name = "NotFoundError";
  }
}

const users = new Map([[1, "سارة"]]);

function findUser(id) {
  if (!users.has(id)) throw new NotFoundError(`المستخدم #${id}`);
  return users.get(id);
}

function loadProfile(id) {
  try {
    return findUser(id);
  } catch (error) {
    throw new Error("تعذّر تحميل الملف الشخصي", { cause: error }); // احتفظ بالخطأ الأصلي سبباً
  }
}

try {
  loadProfile(7);
} catch (error) {
  console.log(error.message);
  console.log("السبب:", error.cause.name, "-", error.cause.message);
  console.log(error.cause instanceof NotFoundError);
}
