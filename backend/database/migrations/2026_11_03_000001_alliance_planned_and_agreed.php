<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 40 D1, D2] The alliance tournament planned as its league is made: how its teams are shared (the draw, or the
 * maker's own split by username), and when they were (formed_at). A tie of two coaches of one alliance: each one's
 * choice of who goes on, and the players the one who goes on swapped with the other. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('alliance_tournaments', function (Blueprint $t) {
            $t->string('assign', 5)->nullable();
            $t->json('plan')->nullable();
            $t->timestamp('formed_at')->nullable();
        });
        Schema::table('alliance_ties', function (Blueprint $t) {
            $t->unsignedBigInteger('home_pick')->nullable();
            $t->unsignedBigInteger('away_pick')->nullable();
            $t->unsignedTinyInteger('swaps')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('alliance_ties', fn (Blueprint $t) => $t->dropColumn(['home_pick', 'away_pick', 'swaps']));
        Schema::table('alliance_tournaments', fn (Blueprint $t) => $t->dropColumn(['assign', 'plan', 'formed_at']));
    }
};
