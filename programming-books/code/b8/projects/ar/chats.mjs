import {chat, loadProject, text} from "./lib/project.mjs";

const support = loadProject("support");

// ثلاث محادثات في المشروع نفسه: تُكتب المعرفة في الذاكرة المؤقتة مرة، ثم
// تُقرأ.
for (const [i, question] of ["كم سعر اللاتيه بالورد؟", "هل في أي صنف مكسرات؟", "هل يوجد موقف سيارات في فرع الزمالك؟"].entries()) {
  const response = await chat(support, question);
  const u = response.usage;
  console.log(`> ${question}\n${text(response)}`);
  console.log(`  (المحادثة ${i + 1}: ${u.cache_creation_input_tokens} كُتب في الذاكرة المؤقتة، ` +
    `${u.cache_read_input_tokens} قُرئ من الذاكرة المؤقتة، ${u.input_tokens} جديدة)`);
}
