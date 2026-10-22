<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * League matches [PLAN 2.12, 4]. A match keeps what replays it to the letter: the seed, the engine version
 * and the config snapshot taken at kick-off, and its starting state. While it is live its state lives in the
 * cache; the row is written at half-time and at the end. Its events and each club's numbers stay after it.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('seed');
            $table->unsignedSmallInteger('engine_version');
            $table->json('config_snapshot');
            // The state at kick-off: the seed, this and the orders (Sprint 19) give the same match again.
            $table->json('initial_state');
            // Kept at half-time and at the end; the live minutes are in the cache.
            $table->json('state');
            $table->unsignedTinyInteger('tick')->default(0);
            $table->unsignedTinyInteger('home_goals')->default(0);
            $table->unsignedTinyInteger('away_goals')->default(0);
            // live: played minute by minute and broadcast; instant: simulated at once (bot against bot, or long missed).
            $table->string('mode', 8);
            $table->string('status', 10)->default('live');
            // When the next minute starts on the server clock (ms), while live.
            $table->unsignedBigInteger('next_at')->nullable();
            // An instant match is shown as ended only at its natural end.
            $table->timestamp('publish_at')->nullable();
            $table->timestamp('started_at');
            $table->timestamp('finished_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'next_at']);
        });

        Schema::create('match_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('tick');
            $table->unsignedTinyInteger('minute');
            $table->string('type', 12);
            $table->foreignId('club_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('player_id')->nullable()->constrained()->nullOnDelete();
            $table->json('payload');

            $table->index(['match_id', 'tick']);
        });

        Schema::create('match_stats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            // The engine's counters for the side (attacks, shots, xg...), and each player's minutes, rating and fitness.
            $table->json('counters');
            $table->json('players');

            $table->unique(['match_id', 'club_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_stats');
        Schema::dropIfExists('match_events');
        Schema::dropIfExists('matches');
    }
};
