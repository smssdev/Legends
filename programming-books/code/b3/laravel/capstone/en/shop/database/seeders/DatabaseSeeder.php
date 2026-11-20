<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        foreach ([['Robot kit', 45000, 5], ['Spare wheels', 6000, 50], ['Soldering iron', 18000, 12],
            ['Battery pack', 9000, 30], ['Sensor set', 25000, 8]] as [$name, $price, $stock]) {
            Product::create(compact('name', 'price', 'stock'));
        }
    }
}
