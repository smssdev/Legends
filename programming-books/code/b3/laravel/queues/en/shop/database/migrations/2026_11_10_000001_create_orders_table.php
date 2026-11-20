<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('email');
        });
        DB::table('orders')->insert([
            ['id' => 1001, 'email' => 'sara@example.com'],
            ['id' => 1002, 'email' => 'omar@example.com'],
            ['id' => 1003, 'email' => 'lina@example.com'],
            ['id' => 1004, 'email' => 'karim-at-example.com'],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
