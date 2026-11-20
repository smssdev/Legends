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
  run(timer.tick); // the method is passed without its object
} catch (error) {
  console.log("Lost this:", error.message);
}

run(() => timer.tick()); // fix 1: call it inside an arrow function
run(timer.tick.bind(timer)); // fix 2: bind it to the object
run(timer.tickArrow); // fix 3: an arrow-function field keeps this
console.log(timer.seconds);
