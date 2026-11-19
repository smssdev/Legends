<?php

declare(strict_types=1); // strict types: no silent conversions in this file

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total(45000, 2));
var_dump(total("45000", 2));
