<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The economy [PLAN 2.7, 2.9, Sprint 23]: the league's money scale, each club's rounds in debt, and the
 * sponsor of each stadium sector, chosen for the season.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $table) {
            // The average squad value when the league starts: wages, income and prizes are shares of it.
            $table->unsignedBigInteger('money_scale')->nullable();
        });
        Schema::table('clubs', function (Blueprint $table) {
            // League rounds in a row ended below zero; at 3 the dearest player goes to the pool [PLAN 2.7].
            $table->unsignedTinyInteger('debt_rounds')->default(0);
        });
        Schema::create('sponsor_contracts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('sector', 10);
            $table->string('offer', 10);
            $table->timestamp('created_at');

            // One sponsor per sector for the season: chosen once.
            $table->unique(['club_id', 'season_id', 'sector']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sponsor_contracts');
        Schema::table('clubs', fn (Blueprint $table) => $table->dropColumn('debt_rounds'));
        Schema::table('leagues', fn (Blueprint $table) => $table->dropColumn('money_scale'));
    }
};
