<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The orders given during a league match [PLAN 2.12, Sprint 19]: the coach's, his assistant's when he is away,
 * and the computer's for a bot. Each is kept with the minute it was applied in, so the seed, the starting
 * state and these give the same match again, to the letter.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_actions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->string('side', 4);
            // coach, assistant (the coach is away), or cpu (a bot).
            $table->string('source', 10);
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('idempotency_key', 64);
            // Not before this minute; applied_tick is the minute it really went in (a late order goes in the next).
            $table->unsignedTinyInteger('target_tick');
            $table->unsignedTinyInteger('applied_tick')->nullable();
            // The order as the engine reads it (type sub, tactics or formation, without the team).
            $table->json('action');
            $table->timestamp('created_at');

            $table->unique(['match_id', 'idempotency_key']);
            $table->index(['match_id', 'applied_tick']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_actions');
    }
};
