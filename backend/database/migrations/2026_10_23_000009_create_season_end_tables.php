<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The end of a season [PLAN 2.11, 2.20, Sprint 33]: each club's objectives (a place in the league, a stage in the
 * cup) and whether its coach met them, and the titles: who won what, kept for good across seasons.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_objectives', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('competition', 6);      // league, cup
            $table->string('target', 12);          // league: a place ("3"); cup: a stage ("sf")
            $table->string('kind', 8);             // league: title, top, mid, survive; cup: the stage
            $table->string('result', 12)->nullable();   // the place reached, or the last stage reached
            $table->boolean('achieved')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();   // the coach judged at the end
            $table->timestamps();

            $table->unique(['club_id', 'season_id', 'competition']);
        });
        Schema::create('titles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();   // empty: a bot's
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('competition', 6);
            $table->unsignedTinyInteger('position');   // league 1 to 3; cup 1 (winner) and 2 (finalist)
            $table->timestamps();

            $table->unique(['season_id', 'competition', 'position']);
            $table->index('user_id');
        });
        Schema::table('seasons', function (Blueprint $table) {
            $table->timestamp('finished_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('seasons', fn (Blueprint $table) => $table->dropColumn('finished_at'));
        Schema::dropIfExists('titles');
        Schema::dropIfExists('club_objectives');
    }
};
