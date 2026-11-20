<?php

namespace App\Orders\Domain;

final readonly class PlacedOrder
{
    public function __construct(public int $id, public string $email, public int $total) {}
}
