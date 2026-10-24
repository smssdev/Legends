<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Selling [X6, 2026-10-24]: a listed player goes to a buyer from outside the league at his price when sells_at comes
 * (later the dearer he is), unless a coach buys him first. And the pool renews every few hours: when it last did.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transfer_listings', function (Blueprint $table) {
            $table->timestamp('sells_at')->nullable()->index();
        });
        Schema::table('leagues', function (Blueprint $table) {
            $table->timestamp('pool_renewed_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('leagues', fn (Blueprint $table) => $table->dropColumn('pool_renewed_at'));
        Schema::table('transfer_listings', function (Blueprint $table) {
            $table->dropIndex(['sells_at']);
            $table->dropColumn('sells_at');
        });
    }
};
