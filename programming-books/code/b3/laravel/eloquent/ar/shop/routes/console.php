<?php

use App\Models\Order;
use App\Models\Product;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

// كل استعلام يرسله Laravel، معدوداً
function countQueries(callable $work): array
{
    $queries = [];
    DB::listen(function ($query) use (&$queries) {
        $queries[] = $query->sql;
    });
    $result = $work();
    DB::flushQueryLog();

    return [$result, $queries];
}

Artisan::command('shop:order {id}', function (int $id) {
    [$order, $queries] = countQueries(
        fn () => Order::with(['customer', 'products'])->findOrFail($id),
    );
    $this->line("#{$order->id} {$order->customer->name} · {$order->status->label()} · {$order->total}");
    foreach ($order->products as $product) {
        $this->line("  {$product->pivot->quantity} × {$product->name} ({$product->pivot->price})");
    }
    foreach ($queries as $sql) {
        $this->line("SQL: $sql");
    }
});

Artisan::command('shop:report {mode}', function (string $mode) {
    $start = hrtime(true);
    [$orders, $queries] = countQueries(function () use ($mode) {
        $orders = $mode === 'eager'
            ? Order::shipped()->with('products')->get() // استعلامان: الطلبات، ثم كل منتجاتها دفعة واحدة
            : Order::shipped()->get();
        // كل ->products يحمّل منتجات ذلك الطلب: استعلام إضافي لكل طلب
        $orders->each(fn (Order $order) => $order->products->count());

        return $orders;
    });
    $ms = intdiv(hrtime(true) - $start, 1_000_000);
    $this->line(sprintf('%-5s %d طلبات, %d استعلامات, %d ms', $mode, $orders->count(),
        count($queries), $ms));
});

Artisan::command('shop:mass', function () {
    $product = Product::make(['name' => 'Test', 'price' => 100, 'stock' => 1]);
    $this->line(json_encode($product->only(['name', 'price', 'stock']), JSON_UNESCAPED_UNICODE));
    Product::make(['name' => 'Test', 'price' => 100, 'id' => 1]);
});

// The answers to exercises 2 and 4.
Artisan::command('shop:answers', function () {
    $this->line('shipped: '.Order::shipped()->count());
    $units = Product::withSum('orders as units', 'order_items.quantity')->orderBy('id')->get();
    foreach ($units as $product) {
        $this->line("{$product->name}: ".($product->units ?? 0));
    }
});
