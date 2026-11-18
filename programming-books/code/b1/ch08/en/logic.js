const isMember = true;
const day = "Tuesday";

if (isMember && day === "Tuesday") {
  console.log("Half price today!");
}

const hasTicket = false;
if (!hasTicket) {
  console.log("Please buy a ticket.");
}

const nickname = "";
const shown = nickname || "Guest";
console.log(shown);
