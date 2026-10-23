<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The market pool [PLAN 2.7, Sprint 24]: about 300 players from outside the league's clubs, renewed when each
 * window opens. A player with no club is in the pool while in_pool is set; a renewal takes the old ones out.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->boolean('in_pool')->default(false);
            $table->index(['league_id', 'in_pool']);
        });
        Schema::table('transfer_windows', function (Blueprint $table) {
            $table->timestamp('pool_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('transfer_windows', fn (Blueprint $table) => $table->dropColumn('pool_at'));
        Schema::table('players', function (Blueprint $table) {
            $table->dropIndex(['league_id', 'in_pool']);
            $table->dropColumn('in_pool');
        });
    }
};
