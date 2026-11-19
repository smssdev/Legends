<?php

declare(strict_types=1);

// One type, two uses: a list (keys 0, 1, 2...) and a map (keys you choose).
$prices = [45000, 6000, 12500];
$product = ['id' => 1, 'name' => 'Robot kit', 'price' => 45000];

$prices[] = 2500; // push
echo count($prices), ' ', $product['name'], ' ', $product['stock'] ?? 0, "\n";

// Unlike JavaScript, assigning an array copies it
$copy = $prices;
$copy[] = 99;
echo count($prices), ' ', count($copy), "\n";

// Destructuring, like JavaScript
[$first, $second] = $prices;
['name' => $name, 'price' => $price] = $product;
echo "$first $second $name $price\n";

// map, filter, reduce: careful, the order of the arguments differs
$cheap = array_filter($prices, fn (int $p) => $p < 10000);
$doubled = array_map(fn (int $p) => $p * 2, $prices);
$sum = array_reduce($prices, fn (int $carry, int $p) => $carry + $p, 0);
print_r($cheap); // the keys are kept: 1 and 3, not 0 and 1
echo json_encode(array_values($cheap)), ' ', json_encode($doubled), " $sum\n";

// PHP 8.4: find, any, all
$big = array_find($prices, fn (int $p) => $p > 10000);
$any = array_any($prices, fn (int $p) => $p > 40000);
$all = array_all($prices, fn (int $p) => $p > 0);
var_dump($big, $any, $all);

// PHP 8.5: the pipe operator passes the value on the left to the callable on the right
$label = '  Robot kit  ' |> trim(...) |> mb_strtoupper(...) |> (fn (string $s) => "[$s]");
echo $label, "\n";
