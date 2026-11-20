import { db } from "../src/db.ts";

const rows = await db.selectFrom("products").select(["name", "prise"]).execute(); // عمود غير موجود
console.log(rows[0]?.name.toUpperCase());
