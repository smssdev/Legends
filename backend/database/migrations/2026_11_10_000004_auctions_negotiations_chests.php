<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 50 M18, M19, M21] The market's auctions (a listing with an end, and its bids), a coach's negotiation with a
 * computer club over one player, and the store chests' openings (each kept as it fell, never changed).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transfer_listings', function (Blueprint $t) {
            $t->timestamp('auction_ends_at')->nullable()->index();
        });
        Schema::create('auction_bids', function (Blueprint $t) {
            $t->id();
            $t->foreignId('player_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->unsignedBigInteger('amount');
            $t->string('idempotency_key', 64)->unique();
            $t->timestamp('created_at')->nullable();
            $t->index(['player_id', 'amount']);
        });
        Schema::create('bot_negotiations', function (Blueprint $t) {
            $t->id();
            $t->foreignId('club_id')->constrained()->cascadeOnDelete();
            $t->foreignId('player_id')->constrained()->cascadeOnDelete();
            $t->unsignedTinyInteger('round')->default(0);
            $t->unsignedBigInteger('ask');
            $t->string('status', 10)->default('open');
            $t->timestamp('expires_at');
            $t->timestamps();
            $t->unique(['club_id', 'player_id']);
        });
        Schema::create('chest_openings', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('club_id')->nullable()->constrained()->nullOnDelete();
            $t->string('chest', 12);
            $t->unsignedInteger('roll');
            $t->string('reward', 8);
            $t->unsignedBigInteger('amount');
            $t->string('idempotency_key', 64)->unique();
            $t->timestamp('created_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chest_openings');
        Schema::dropIfExists('bot_negotiations');
        Schema::dropIfExists('auction_bids');
        Schema::table('transfer_listings', function (Blueprint $t) {
            $t->dropIndex(['auction_ends_at']);
            $t->dropColumn('auction_ends_at');
        });
    }
};
