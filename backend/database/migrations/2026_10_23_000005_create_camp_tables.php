<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The training camp and secret training [docs/features/camp.md, docs/features/secret-training.md, Sprint 28]:
 * a club's camp with its players, level, sessions and return; and the secret session ordered for one fixture.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_camps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('level', 8);
            $table->json('player_ids');
            $table->json('gains')->nullable();     // player id => points gained at the camp
            $table->unsignedSmallInteger('sessions');
            $table->unsignedSmallInteger('sessions_done')->default(0);
            $table->unsignedBigInteger('cost');
            $table->timestamp('next_at');
            $table->timestamp('ends_at');
            $table->string('status', 8)->default('active');   // active, done
            $table->string('idempotency_key', 80)->unique();
            $table->timestamps();

            $table->index(['status', 'next_at']);
        });
        Schema::create('secret_trainings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->string('line', 3);
            $table->unsignedBigInteger('cost');
            $table->timestamps();

            $table->unique(['club_id', 'fixture_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('secret_trainings');
        Schema::dropIfExists('training_camps');
    }
};
