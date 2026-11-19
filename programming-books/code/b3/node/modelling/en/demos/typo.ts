import { db } from "../src/db.ts";

const rows = await db.selectFrom("products").select(["name", "prise"]).execute(); // a column that does not exist
console.log(rows[0]?.name.toUpperCase());
