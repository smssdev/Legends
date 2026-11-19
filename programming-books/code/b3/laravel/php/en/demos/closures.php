<?php

declare(strict_types=1);

$discount = 10;
// fn captures by value, automatically
$apply = fn (int $price): int => $price - intdiv($price * $discount, 100);
$discount = 50; // too late: fn already copied 10
echo $apply(45000), "\n";

$count = 0;
// function () needs use to capture, also by value
$increment = function () use ($count): int {
    return ++$count;
};
$increment();
$increment();
echo $count, "\n"; // still 0: the closure changed its own copy

// &$count: by reference, the JavaScript way
$counter = function () use (&$count): void {
    $count++;
};
$counter();
$counter();
echo $count, "\n";

// Named arguments: skip to the one you need, in any order
echo str_pad(string: '7', length: 3, pad_string: '0', pad_type: STR_PAD_LEFT), "\n";
echo json_encode(['name' => 'Robot kit'], flags: JSON_UNESCAPED_UNICODE), "\n";
