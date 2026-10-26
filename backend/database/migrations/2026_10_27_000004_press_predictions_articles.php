<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [UP12] The owner's spec (6): the coach's statement at the press conference before each match, the coaches'
 * predictions of the round's winners, and the articles they write for the league's newspaper.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('press_statements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('kind', 10);   // attack, calm, rally
            $table->timestamp('created_at');
            $table->unique(['fixture_id', 'club_id']);
        });
        Schema::create('match_predictions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('pick', 4);   // home, draw, away
            $table->boolean('correct')->nullable();
            $table->timestamps();
            $table->unique(['fixture_id', 'user_id']);
            $table->index(['user_id', 'correct']);
        });
        Schema::create('league_articles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title', 120);
            $table->text('body');
            $table->string('status', 10)->default('pending');   // pending, published, rejected
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();
            $table->index(['league_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('league_articles');
        Schema::dropIfExists('match_predictions');
        Schema::dropIfExists('press_statements');
    }
};
