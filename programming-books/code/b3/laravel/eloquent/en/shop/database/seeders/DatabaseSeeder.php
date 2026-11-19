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
        $sara = Customer::create(['name' => 'Sara', 'email' => 'sara@example.com']);
        Customer::create(['name' => 'Omar', 'email' => 'omar@example.com']);
        Customer::create(['name' => 'Lina', 'email' => 'lina@example.com']);

        $products = collect([
            ['Robot kit', 45000], ['Spare wheels', 6000], ['Battery pack', 12500], ['USB cable', 2500],
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
