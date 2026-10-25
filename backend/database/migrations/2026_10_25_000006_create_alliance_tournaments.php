<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** The alliance tournament [X27]: two alliances of the league's coaches, approved by the developers, and its ties. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('alliance_tournaments', function (Blueprint $t) {
            $t->id();
            $t->foreignId('league_id')->constrained()->cascadeOnDelete();
            $t->foreignId('season_id')->constrained()->cascadeOnDelete();
            $t->string('name', 40);
            // pending (with the developers), rejected, running, finished.
            $t->string('status', 10)->default('pending');
            $t->unsignedTinyInteger('size');
            $t->foreignId('captain_a')->constrained('users');
            $t->foreignId('captain_b')->constrained('users');
            $t->timestamp('first_round_at');
            $t->unsignedInteger('round_gap_minutes');
            $t->unsignedBigInteger('seed');
            $t->string('winner', 1)->nullable();
            $t->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamp('reviewed_at')->nullable();
            $t->string('review_note', 200)->nullable();
            $t->timestamps();
            $t->index(['league_id', 'status']);
        });
        Schema::create('alliance_members', function (Blueprint $t) {
            $t->id();
            $t->foreignId('tournament_id')->constrained('alliance_tournaments')->cascadeOnDelete();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->string('alliance', 1);
            $t->unique(['tournament_id', 'club_id']);
        });
        Schema::create('alliance_ties', function (Blueprint $t) {
            $t->id();
            $t->foreignId('tournament_id')->constrained('alliance_tournaments')->cascadeOnDelete();
            $t->unsignedTinyInteger('round');
            // match (played), bye, captain (two team-mates: their captain picks), walkover (a final of team-mates).
            $t->string('kind', 9);
            $t->foreignId('home_id')->constrained('clubs');
            $t->foreignId('away_id')->nullable()->constrained('clubs');
            $t->foreignId('fixture_id')->nullable()->constrained()->nullOnDelete();
            $t->timestamp('scheduled_at');
            $t->foreignId('winner_id')->nullable()->constrained('clubs');
            $t->timestamps();
            $t->index(['tournament_id', 'round']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('alliance_ties');
        Schema::dropIfExists('alliance_members');
        Schema::dropIfExists('alliance_tournaments');
    }
};
