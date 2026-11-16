<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 74 P2] How smoothly the app draws on the players' phones, as counts only: per day, app version, the phone's
 * tier (low, mid, high) and screen (its path without ids), how many frames were drawn and how many of them late (over
 * 16 ms, over 33 ms), and from how many sessions. No account, no address, no device name. Kept 30 days.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('client_frames', function (Blueprint $t) {
            $t->id();
            $t->date('day')->index();
            $t->string('platform', 10);
            $t->string('version', 20);
            $t->string('tier', 4);
            $t->string('path', 200);
            $t->unsignedBigInteger('frames')->default(0);
            $t->unsignedBigInteger('late16')->default(0);
            $t->unsignedBigInteger('late33')->default(0);
            $t->unsignedInteger('sessions')->default(0);
            $t->unique(['day', 'platform', 'version', 'tier', 'path']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('client_frames');
    }
};
