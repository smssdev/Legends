import {ask, readProject} from "./lib/ask.mjs";

// كل ملفات المشروع، بأسمائها، كما يفتحها قادم جديد.
const project = readProject("legacy");
console.log(await ask(`هذا مشروع لم أره من قبل. من الملفات أدناه، قل في سطر واحد لكل ملف ماذا يفعل، ثم أي ملف يعمل أولاً. باختصار.\n\n${project}`));
