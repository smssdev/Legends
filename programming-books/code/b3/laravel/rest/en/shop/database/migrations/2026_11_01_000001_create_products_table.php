<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name', 80);
            $table->unsignedInteger('price'); // piastres
            $table->unsignedInteger('stock')->default(0);
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            // the list is sorted by price, then id: the index serves both
            $table->index(['price', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
