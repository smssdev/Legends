<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 23] The admin's timed events (transfer madness, extreme progression, the market's discount, special
 * offers, players of the week, legends), in every league (league_id null) or in one. And the pool's special
 * players: their kind, and their price in bp of the value (an offer's discount, a legend's premium).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('timed_events', function (Blueprint $table) {
            $table->id();
            $table->string('kind', 16);
            $table->foreignId('league_id')->nullable()->constrained()->cascadeOnDelete();
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->index();
            $table->unsignedInteger('power');
            $table->unsignedSmallInteger('count')->default(0);
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
            $table->index(['kind', 'starts_at']);
        });
        Schema::table('players', function (Blueprint $table) {
            $table->string('pool_kind', 10)->nullable();
            $table->unsignedInteger('pool_price_bp')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('players', fn (Blueprint $table) => $table->dropColumn(['pool_kind', 'pool_price_bp']));
        Schema::dropIfExists('timed_events');
    }
};
