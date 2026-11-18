// Contrast ratio between two colours, using the WCAG formula
function luminance(hex) {
  const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const linear = channels.map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
}

function contrast(foreground, background) {
  const [a, b] = [luminance(foreground), luminance(background)].sort((x, y) => y - x);
  return (a + 0.05) / (b + 0.05);
}

const pairs = [
  ["#1e1b2e", "#ffffff"],
  ["#4338ca", "#ffffff"],
  ["#9ca3af", "#ffffff"],
  ["#ffffff", "#fbbf24"],
];

for (const [fg, bg] of pairs) {
  const ratio = contrast(fg, bg);
  const verdict = ratio >= 4.5 ? "pass" : "fail";
  console.log(`${fg} / ${bg}: ${ratio.toFixed(2)} → ${verdict}`);
}
