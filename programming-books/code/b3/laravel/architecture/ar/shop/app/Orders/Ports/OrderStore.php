<?php

namespace App\Orders\Ports;

use App\Orders\Domain\PlacedOrder;
use DateTimeImmutable;

// منفذ: ما يحتاجه الفعل، كما يصفه هو
interface OrderStore
{
    /**
     * Takes the stock and saves the order, all or nothing; prices come from the store.
     *
     * @param  list<array{product_id: int, quantity: int}>  $items
     */
    public function place(string $email, array $items, DateTimeImmutable $placedAt): PlacedOrder;
}
