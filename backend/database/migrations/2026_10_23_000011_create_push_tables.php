<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Notifications [PLAN 2.13, Sprint 36]: the browsers (and installed sites) an account gets pushes on, which kinds
 * it wants, and when each fixture's "in 10 minutes" went out (once).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('push_subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('channel', 8)->default('webpush');   // webpush now; fcm in Sprint 45, on the same channel
            $table->string('endpoint', 600)->unique();
            $table->string('p256dh', 200)->nullable();
            $table->string('auth', 100)->nullable();
            $table->timestamps();
        });
        Schema::table('users', function (Blueprint $table) {
            $table->json('notify_prefs')->nullable();   // kind => false for the kinds turned off; empty = all on
        });
        Schema::table('fixtures', function (Blueprint $table) {
            $table->timestamp('soon_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('fixtures', fn (Blueprint $table) => $table->dropColumn('soon_at'));
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('notify_prefs'));
        Schema::dropIfExists('push_subscriptions');
    }
};
