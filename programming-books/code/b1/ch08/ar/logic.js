const isMember = true;
const day = "الثلاثاء";

if (isMember && day === "الثلاثاء") {
  console.log("نصف السعر اليوم!");
}

const hasTicket = false;
if (!hasTicket) {
  console.log("من فضلك اشترِ تذكرة.");
}

const nickname = "";
const shown = nickname || "ضيف";
console.log(shown);
