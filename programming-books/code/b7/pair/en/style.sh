$ node style.mjs
== without an example
import json

def load_menu():
    """
    Loads the menu from 'menu.json' file.
    
    Returns:
        dict or list: The menu data as a dictionary or list, or None if file not found or invalid.
    """
    try:
        with open('menu.json', 'r', encoding='utf-8') as file:
            menu_data = json.load(file)
        return menu_data
    except FileNotFoundError:
        print("Error: menu.json file not found.")
        return None
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON format in menu.json - {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None

# Example usage:
# menu = load_menu()
# if menu:
#     print("Menu loaded successfully:", menu)

== with house/tables.mjs
// Loads the menu from menu.json; an empty object if the file is missing.
export async function loadMenu(path = "menu.json") {
  try {
    return JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return {};
    }
    throw error;
  }
}
