<?php

namespace Database\Seeders;

use App\Models\Customer;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $sara = Customer::create(['name' => 'سارة', 'email' => 'sara@example.com']);
        Customer::create(['name' => 'عمر', 'email' => 'omar@example.com']);
        Customer::create(['name' => 'لينا', 'email' => 'lina@example.com']);

        $products = collect([
            ['عدة الروبوت', 45000], ['عجلات احتياطية', 6000], ['حزمة بطارية', 12500], ['كابل USB', 2500],
        ])->map(fn ($p, $i) => Product::create([
            'name' => $p[0], 'price' => $p[1], 'stock' => 10, 'sku' => sprintf('BIT-%04d', $i + 1),
        ]));

        // Sara gets 200 orders of 1 to 3 products, for counting queries.
        foreach (range(1, 200) as $n) {
            $order = Order::create(['customer_id' => $sara->id, 'status' => 'shipped']);
            foreach ($products->take(1 + $n % 3) as $product) {
                $order->products()->attach($product->id, ['quantity' => 1, 'price' => $product->price]);
            }
        }
    }
}
