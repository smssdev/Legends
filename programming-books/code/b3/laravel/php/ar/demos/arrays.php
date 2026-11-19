<?php

declare(strict_types=1);

// نوع واحد واستخدامان: قائمة (مفاتيحها 0 و1 و2...) وخريطة (مفاتيح تختارها).
$prices = [45000, 6000, 12500];
$product = ['id' => 1, 'name' => 'عدة الروبوت', 'price' => 45000];

$prices[] = 2500; // إضافة إلى الآخر
echo count($prices), ' ', $product['name'], ' ', $product['stock'] ?? 0, "\n";

// بخلاف JavaScript، إسناد المصفوفة ينسخها
$copy = $prices;
$copy[] = 99;
echo count($prices), ' ', count($copy), "\n";

// التفكيك، كما في JavaScript
[$first, $second] = $prices;
['name' => $name, 'price' => $price] = $product;
echo "$first $second $name $price\n";

// map وfilter وreduce: انتبه، ترتيب المعاملات يختلف
$cheap = array_filter($prices, fn (int $p) => $p < 10000);
$doubled = array_map(fn (int $p) => $p * 2, $prices);
$sum = array_reduce($prices, fn (int $carry, int $p) => $carry + $p, 0);
print_r($cheap); // تبقى المفاتيح: 1 و3، لا 0 و1
echo json_encode(array_values($cheap)), ' ', json_encode($doubled), " $sum\n";

// PHP 8.4: البحث، وأيٌّ، وكلٌّ
$big = array_find($prices, fn (int $p) => $p > 10000);
$any = array_any($prices, fn (int $p) => $p > 40000);
$all = array_all($prices, fn (int $p) => $p > 0);
var_dump($big, $any, $all);

// PHP 8.5: عامل الأنبوب يمرر القيمة التي على يساره إلى الدالة التي على يمينه
$label = '  عدة الروبوت  ' |> trim(...) |> mb_strtoupper(...) |> (fn (string $s) => "[$s]");
echo $label, "\n";
