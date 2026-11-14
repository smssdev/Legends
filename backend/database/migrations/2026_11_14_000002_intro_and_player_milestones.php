<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 64 B1, B2] When a new coach started and finished the intro match (the funnel's first two steps; the rest
 * is read from the game itself). [B8] Each player's milestones with his club (the tenth goal, the fiftieth match, the
 * first man of the match), once each, and when the coach saw its card.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $t) {
            $t->timestamp('intro_started_at')->nullable();
            $t->timestamp('intro_finished_at')->nullable();
        });
        Schema::create('player_milestones', function (Blueprint $t) {
            $t->id();
            $t->foreignId('player_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->foreignId('match_id')->nullable()->constrained()->nullOnDelete();
            $t->string('kind', 16);
            $t->unsignedSmallInteger('value');
            $t->timestamp('seen_at')->nullable();
            $t->timestamp('created_at')->nullable();
            $t->unique(['player_id', 'kind', 'value']);
            $t->index(['club_id', 'seen_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('player_milestones');
        Schema::table('users', function (Blueprint $t) {
            $t->dropColumn(['intro_started_at', 'intro_finished_at']);
        });
    }
};
