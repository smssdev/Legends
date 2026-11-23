import fs from "node:fs";
import {ask, codeOf} from "./lib/ask.mjs";

// The same task without and with one file of the project to copy the
// style from.
const task = "Write a function that loads the menu from menu.json.";
const house = fs.readFileSync("house/tables.mjs", "utf8");

console.log("== without an example\n" + codeOf(await ask(task)));
const withHouse = `This is a file from our project. Write the new function in the same style.\n\n${house}\n${task}`;
console.log("== with house/tables.mjs\n" + codeOf(await ask(withHouse)));
