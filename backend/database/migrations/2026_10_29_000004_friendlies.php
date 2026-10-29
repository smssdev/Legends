<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 20 B4] The friendlies a coach played: against whom, the score and the report. Nothing else in the game
// reads them: no table, no money, no fitness, no injury.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('friendlies', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('opponent_id')->constrained('clubs')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedBigInteger('seed');
            $table->unsignedTinyInteger('goals_for');
            $table->unsignedTinyInteger('goals_against');
            $table->json('report');
            $table->date('day');               // Cairo's day, for the daily limit
            $table->timestamp('created_at');
            $table->index(['club_id', 'day']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('friendlies');
    }
};
