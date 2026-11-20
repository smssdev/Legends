<?php

declare(strict_types=1);

namespace Shop;

use InvalidArgumentException;

// readonly: تُضبط مرة واحدة في المُنشئ، ولا تتغير بعدها
final readonly class Money
{
    // ترقية المُنشئ: المعاملات هي الخصائص نفسها
    public function __construct(
        public int $amount, // بالوحدات الصغرى: قروش، هللات، سنتات
        public Currency $currency,
    ) {
        if ($amount < 0) {
            throw new InvalidArgumentException('لا يجوز أن يكون المبلغ سالباً');
        }
    }

    public function plus(Money $other): Money
    {
        if ($other->currency !== $this->currency) {
            throw new CurrencyMismatch($this->currency, $other->currency);
        }
        return new Money($this->amount + $other->amount, $this->currency);
    }

    public function times(int $quantity): Money
    {
        return new Money($this->amount * $quantity, $this->currency);
    }

    public function format(): string
    {
        $decimals = $this->currency->decimals();
        $unit = 10 ** $decimals;
        $minor = str_pad((string) ($this->amount % $unit), $decimals, '0', STR_PAD_LEFT);
        return "{$this->currency->symbol()} " . number_format(intdiv($this->amount, $unit)) . ".$minor";
    }
}
