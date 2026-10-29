<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 24] A friendly keeps the coach's players who played in it (they count for chemistry) and the key of the
 * request that paid for it (a repeated tap plays it once). And an account keeps how many of its slots it was told
 * are open, so each new one is announced once (null: not counted yet, so the first count announces nothing), and
 * the last slot it opened early for coins (they stay open for good).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('friendlies', function (Blueprint $table) {
            $table->json('players')->nullable();
            $table->string('idempotency_key', 100)->nullable()->unique();
        });
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedTinyInteger('slots_notified')->nullable();
            $table->unsignedTinyInteger('slots_unlocked')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('friendlies', function (Blueprint $table) {
            $table->dropUnique(['idempotency_key']);
            $table->dropColumn(['players', 'idempotency_key']);
        });
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn(['slots_notified', 'slots_unlocked']));
    }
};
