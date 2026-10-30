<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 27 B1, B2, the owner's request 2026-10-30] The league's days off (ISO weekdays in Cairo, e.g. [5] for
 * Friday, chosen before the start), and a match moved by whole hours on its own day when both coaches agree.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leagues', function (Blueprint $table) {
            $table->json('rest_days')->nullable();
        });
        Schema::create('fixture_moves', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();   // the club that asked
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->dateTime('from_at');
            $table->dateTime('to_at');
            $table->string('status', 12)->default('pending');   // pending, accepted, declined, cancelled, expired
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->dateTime('decided_at')->nullable();
            $table->timestamps();
            $table->index(['fixture_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_moves');
        Schema::table('leagues', fn (Blueprint $table) => $table->dropColumn('rest_days'));
    }
};
