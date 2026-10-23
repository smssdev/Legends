<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The scout [docs/features/scout.md, Sprint 26]: a club's search with its criteria and cost, its report time,
 * and the three players found, kept for that club alone until the pool is renewed.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('scout_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->json('criteria');
            $table->unsignedBigInteger('cost');
            // searching, done (players found), empty (none: the cost was paid back)
            $table->string('status', 10)->default('searching');
            $table->timestamp('finishes_at');
            $table->json('result_player_ids')->nullable();
            $table->string('idempotency_key', 80)->unique();
            $table->timestamps();

            $table->index(['status', 'finishes_at']);
        });
        Schema::table('players', function (Blueprint $table) {
            // A scout's find: no club, not in the pool, buyable by this club alone until the pool is renewed.
            $table->foreignId('scouted_by')->nullable()->constrained('clubs')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->dropConstrainedForeignId('scouted_by');
        });
        Schema::dropIfExists('scout_requests');
    }
};
