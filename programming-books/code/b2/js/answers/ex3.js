class InsufficientFundsError extends Error {
  constructor(needed, available) {
    super(`Needed ${needed}, but only ${available} is available`);
    this.name = "InsufficientFundsError";
  }
}

class Account {
  #balance = 0;
  get balance() { return this.#balance; }
  deposit(amount) { this.#balance += amount; return this; }
  withdraw(amount) {
    if (amount > this.#balance) throw new InsufficientFundsError(amount, this.#balance);
    this.#balance -= amount;
    return this;
  }
}

const acc = new Account().deposit(100).withdraw(30);
console.log(acc.balance);
try {
  acc.withdraw(500);
} catch (error) {
  console.log(error instanceof InsufficientFundsError, error.message);
}
