<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 23] What a club paid for a player (the pool, a bot, a scout's find), or his value when he came in a trade
 * between coaches: his cost, from which the profit of selling him outside the league is counted (App\Market\Buyer).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->bigInteger('bought_for')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('players', fn (Blueprint $table) => $table->dropColumn('bought_for'));
    }
};
