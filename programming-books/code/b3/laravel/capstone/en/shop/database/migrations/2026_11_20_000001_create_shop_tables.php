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
            // the cursor pages read products by (price, id)
            $table->index(['price', 'id']);
        });
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained();
            $table->string('idempotency_key', 100);
            $table->string('request_hash', 64);
            $table->integer('total')->default(0);
            $table->timestamps();
            // one order per customer and key: the database refuses a second
            $table->unique(['user_id', 'idempotency_key']);
        });
        Schema::create('order_items', function (Blueprint $table) {
            $table->foreignId('order_id')->constrained();
            $table->foreignId('product_id')->constrained();
            $table->integer('quantity');
            $table->integer('price');
            $table->primary(['order_id', 'product_id']);
        });
        // what must hold whatever the code does: the database guarantees it
        DB::statement('ALTER TABLE products ADD CHECK (price > 0), ADD CHECK (stock >= 0)');
        DB::statement('ALTER TABLE order_items ADD CHECK (quantity > 0)');
    }

    public function down(): void
    {
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('products');
    }
};
