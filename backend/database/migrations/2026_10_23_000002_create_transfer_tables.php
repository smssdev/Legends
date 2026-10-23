<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The market between coaches [PLAN 2.7, Sprint 25]: a coach lists a player at his price; any coach offers money,
 * players or both, and the other accepts, rejects or counters. Every move is kept (player_moves) for the limits
 * against collusion: the price between 50% and 200% of the value, a player not twice between the same two clubs
 * in a season, and a cap on the net money between two clubs in a season.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transfer_listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('price');
            $table->timestamps();
        });

        Schema::create('transfer_offers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            // The coach who offers, and the one who decides.
            $table->foreignId('from_club_id')->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('to_club_id')->constrained('clubs')->cascadeOnDelete();
            // Club money only (never the premium currency), from the one who offers to the other.
            $table->unsignedBigInteger('money')->default(0);
            // When accepted: what the offering club gave beyond what it got (money and its players' value, less the
            // value received). The pair cap adds these up, so a fair trade counts for nothing and an overpaid one in full.
            $table->bigInteger('excess')->nullable();
            // pending, accepted, rejected, countered, cancelled, expired
            $table->string('status', 10)->default('pending');
            $table->foreignId('counter_of')->nullable()->constrained('transfer_offers')->nullOnDelete();
            $table->string('idempotency_key', 80)->unique();
            $table->timestamp('expires_at');
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();

            $table->index(['to_club_id', 'status']);
            $table->index(['from_club_id', 'status']);
        });

        Schema::create('offer_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('offer_id')->constrained('transfer_offers')->cascadeOnDelete();
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            // in: from the other club to the one who offers; out: from the one who offers to the other.
            $table->string('direction', 3);

            $table->unique(['offer_id', 'player_id']);
            $table->index('player_id');
        });

        Schema::create('player_moves', function (Blueprint $table) {
            $table->id();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->foreignId('from_club_id')->nullable()->constrained('clubs')->nullOnDelete();
            $table->foreignId('to_club_id')->nullable()->constrained('clubs')->nullOnDelete();
            // The money that went with him from the buyer to the seller (0 in a swap's player leg).
            $table->bigInteger('price')->default(0);
            $table->foreignId('offer_id')->nullable()->constrained('transfer_offers')->nullOnDelete();
            $table->timestamp('created_at');

            $table->index(['season_id', 'player_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('player_moves');
        Schema::dropIfExists('offer_items');
        Schema::dropIfExists('transfer_offers');
        Schema::dropIfExists('transfer_listings');
    }
};
