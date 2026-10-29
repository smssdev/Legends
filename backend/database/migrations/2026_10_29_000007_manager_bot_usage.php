<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 22 B5] The Assistant Coach's smart answers per coach per day (Cairo), counted against
// config('game.manager_bot.daily_ai'). Only the count: the questions themselves are never kept.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('manager_bot_usage', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('day');
            $table->unsignedInteger('count')->default(0);
            $table->primary(['user_id', 'day']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('manager_bot_usage');
    }
};
