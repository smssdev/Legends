<?php

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total("45000", 2)); // نص من نموذج، يُحوَّل بصمت
var_dump(total(45000, true)); // حتى true تصبح 1
