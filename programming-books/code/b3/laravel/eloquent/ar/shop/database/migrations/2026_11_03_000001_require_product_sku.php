<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // الخطوة 2: املأه للصفوف الموجودة، على دفعات.
        DB::table('products')->whereNull('sku')->chunkById(500, function ($products) {
            foreach ($products as $product) {
                DB::table('products')->where('id', $product->id)
                    ->update(['sku' => sprintf('BIT-%04d', $product->id)]);
            }
        });

        // الخطوة 3، التقليص: لكل صف SKU الآن، فاجعله إلزامياً وفريداً.
        Schema::table('products', function (Blueprint $table) {
            $table->string('sku')->nullable(false)->unique()->change();
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropUnique(['sku']);
            $table->string('sku')->nullable()->change();
        });
    }
};
