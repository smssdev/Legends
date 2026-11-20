class Account {
  #balance = 0; // private field: invisible outside the class
  static count = 0;

  constructor(owner) {
    this.owner = owner;
    Account.count++;
  }

  get balance() {
    return this.#balance;
  }

  deposit(amount) {
    if (amount <= 0) throw new RangeError("Amount must be positive");
    this.#balance += amount;
    return this; // returning this lets calls be chained
  }
}

class SavingsAccount extends Account {
  addInterest(rate) {
    return this.deposit(Math.round(this.balance * rate));
  }
}

const acc = new SavingsAccount("Sara");
acc.deposit(1000).deposit(500).addInterest(0.1);
console.log(acc.owner, acc.balance, Account.count);
console.log(acc instanceof Account);

try {
  acc.deposit(-5);
} catch (error) {
  console.log(error.name + ":", error.message);
}
