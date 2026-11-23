import {ask, readProject} from "./lib/ask.mjs";

// Every file of the project, with its name, as a newcomer would open
// them.
const project = readProject("legacy");
console.log(await ask(`This is a project I have never seen. From the files below, say in one line each what every file does, then which file runs first. Be brief.\n\n${project}`));
