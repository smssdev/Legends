<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Where the coach dragged each player [X5, 2026-10-24]: the ten outfield places ([x, y] in the formation's frame),
 * each inside its line's band, or null for the formation's own places.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('lineups', fn (Blueprint $table) => $table->json('positions')->nullable());
    }

    public function down(): void
    {
        Schema::table('lineups', fn (Blueprint $table) => $table->dropColumn('positions'));
    }
};
