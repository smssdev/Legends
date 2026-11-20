<?php

declare(strict_types=1); // الأنواع الصارمة: لا تحويلات صامتة في هذا الملف

function total(int $price, int $quantity): int
{
    return $price * $quantity;
}

var_dump(total(45000, 2));
var_dump(total("45000", 2));
