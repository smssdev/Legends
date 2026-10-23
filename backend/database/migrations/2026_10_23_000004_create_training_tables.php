<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Training [PLAN 2.8, Sprint 27]: four slots per club, one per line, each with the player in it and when its next
 * session comes. The progress bar lives on the player (out of 10000), so taking him out keeps what he has done.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('line', 3);
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('sessions')->default(0);
            $table->timestamp('next_at');
            $table->timestamps();

            $table->unique(['club_id', 'line']);
            $table->unique('player_id');
            $table->index('next_at');
        });
        Schema::table('players', function (Blueprint $table) {
            $table->unsignedSmallInteger('training_progress')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('players', function (Blueprint $table) {
            $table->dropColumn('training_progress');
        });
        Schema::dropIfExists('training_slots');
    }
};
