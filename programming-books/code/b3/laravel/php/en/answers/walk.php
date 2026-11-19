<?php

declare(strict_types=1);

$prices = [45000, 6000, 12500];
$total = 0;
array_walk($prices, function (int $p) use ($total): void {
    $total += $p;
});
echo $total, "
"; // 0: the closure added to its own copy

array_walk($prices, function (int $p) use (&$total): void {
    $total += $p;
});
echo $total, ' ', array_sum($prices), "
";
