<?php

namespace Database\Seeders;

use App\Models\Product;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $names = [
            'Robot kit',
            'Spare wheels',
            'Battery pack',
            'USB cable',
            'Servo motor',
            'Sensor set',
            'Remote control',
            'Solar panel',
            'Gear box',
            'LED strip',
            'Speaker',
            'Camera module',
        ];
        $prices = [
            45000, 6000, 12500, 2500, 9000, 15000, 8000, 30000, 11000, 4000, 7500, 21000,
        ];
        $start = Carbon::parse('2026-11-01 09:00:00', 'UTC');
        foreach ($names as $i => $name) {
            $product = new Product(['name' => $name, 'price' => $prices[$i]]);
            $product->stock = 10;
            $product->created_at = $start->copy()->addHours($i);
            $product->updated_at = $product->created_at;
            $product->save();
        }
    }
}
