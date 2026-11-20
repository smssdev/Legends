<?php

declare(strict_types=1);

namespace Shop;

final readonly class Product
{
    public function __construct(
        public int $id,
        public string $name,
        public Money $price,
    ) {}

    // PHP 8.5: clone with new values. Nothing changes: you get a changed copy.
    public function onSale(int $percent): static
    {
        $amount = intdiv($this->price->amount * (100 - $percent), 100);
        return clone($this, [
            'name' => "{$this->name} (-{$percent}%)",
            'price' => new Money($amount, $this->price->currency),
        ]);
    }
}
