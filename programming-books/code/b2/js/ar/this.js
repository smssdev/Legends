class Timer {
  seconds = 0;

  tick() {
    this.seconds++;
  }

  tickArrow = () => {
    this.seconds++;
  };
}

const timer = new Timer();
const run = (callback) => callback();

try {
  run(timer.tick); // مُررت الدالة دون كائنها
} catch (error) {
  console.log("ضاع this:", error.message);
}

run(() => timer.tick()); // الحل 1: استدعها داخل دالة سهمية
run(timer.tick.bind(timer)); // الحل 2: اربطها بالكائن بـ bind
run(timer.tickArrow); // الحل 3: حقل بدالة سهمية يحفظ this
console.log(timer.seconds);
