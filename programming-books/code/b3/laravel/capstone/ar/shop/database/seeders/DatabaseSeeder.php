<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([['عدة الروبوت', 45000, 5], ['عجلات احتياطية', 6000, 50], ['كاوية لحام', 18000, 12],
            ['حزمة بطاريات', 9000, 30], ['طقم حساسات', 25000, 8]] as [$name, $price, $stock]) {
            Product::create(compact('name', 'price', 'stock'));
        }
    }
}
