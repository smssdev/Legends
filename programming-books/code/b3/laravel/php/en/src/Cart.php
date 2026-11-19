<?php

declare(strict_types=1);

namespace Shop;

use InvalidArgumentException;

final class Cart
{
    // anyone can read it; only the class can change it
    /** @var array<int, array{product: Product, quantity: int}> */
    public private(set) array $lines = [];

    // a property hook: read like a property, computed like a method
    public Money $total {
        get => array_reduce(
            $this->lines,
            fn (Money $sum, array $line) => $sum->plus(
                $line['product']->price->times($line['quantity']),
            ),
            new Money(0, $this->currency),
        );
    }

    public int $count {
        get => array_sum(array_column($this->lines, 'quantity'));
    }

    public function __construct(public readonly Currency $currency) {}

    public function add(Product $product, int $quantity = 1): static
    {
        if ($quantity < 1) {
            throw new InvalidArgumentException('Quantity must be at least 1');
        }
        $current = $this->lines[$product->id]['quantity'] ?? 0;
        $this->lines[$product->id] = [
            'product' => $product,
            'quantity' => $current + $quantity,
        ];
        return $this;
    }
}
