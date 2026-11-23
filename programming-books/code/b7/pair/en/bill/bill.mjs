export function splitBill(total, people, tipPercent) {
  if (people < 1) {
    throw new RangeError("people must be at least 1");
  }

  const tip = Math.round(total * tipPercent / 100);
  const totalWithTip = total + tip;

  const baseShare = Math.floor(totalWithTip / people);
  const remainder = totalWithTip % people;

  const result = [];
  for (let i = 0; i < people; i++) {
    result.push(baseShare + (i < remainder ? 1 : 0));
  }

  return result;
}
