<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->integer('price');
            $table->integer('stock');
        });
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->integer('total');
            $table->timestampTz('placed_at');
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->foreignId('order_id')->index()->constrained();
            $table->foreignId('product_id')->constrained();
            $table->integer('quantity');
            $table->integer('price');
        });
        DB::table('products')->insert([
            ['id' => 1, 'name' => 'عدة الروبوت', 'price' => 45000, 'stock' => 5],
            ['id' => 2, 'name' => 'عجلات احتياطية', 'price' => 6000, 'stock' => 50],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
    }
};
