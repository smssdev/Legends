$ node style.mjs
== without an example
import json

def load_menu_from_json():
    """
    تحميل القائمة من ملف menu.json
    """
    try:
        with open('menu.json', 'r', encoding='utf-8') as file:
            menu_data = json.load(file)
            return menu_data
    except FileNotFoundError:
        print("الملف menu.json غير موجود.")
        return None
    except json.JSONDecodeError as e:
        print(f"خطأ في تحليل الملف JSON: {e}")
        return None

== with house/tables.mjs
import { readFile } from "node:fs/promises";

// Loads the list of menu items from menu.json; an empty list if the file is missing.
export async function loadMenu(path = "menu.json") {
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return [];
    }
    throw error;
  }
}
