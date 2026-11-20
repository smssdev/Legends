<?php

declare(strict_types=1);

namespace Shop;

use InvalidArgumentException;

final class Cart
{
    // يقرؤها الجميع، ولا يغيّرها إلا الصنف نفسه
    /** @var array<int, array{product: Product, quantity: int}> */
    public private(set) array $lines = [];

    // خطّاف خاصية: يُقرأ كخاصية، ويُحسب كدالة
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
            throw new InvalidArgumentException('يجب أن تكون الكمية 1 على الأقل');
        }
        $current = $this->lines[$product->id]['quantity'] ?? 0;
        $this->lines[$product->id] = [
            'product' => $product,
            'quantity' => $current + $quantity,
        ];
        return $this;
    }
}
