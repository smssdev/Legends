<?php

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total("45000", 2)); // a string from a form, converted quietly
var_dump(total(45000, true)); // even true becomes 1
