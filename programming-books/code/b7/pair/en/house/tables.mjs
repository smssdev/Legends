import {readFile} from "node:fs/promises";

// Loads the list of tables from tables.json; an empty list if the file is
// missing.
export async function loadTables(path = "tables.json") {
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}
