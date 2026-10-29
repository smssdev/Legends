<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 20 B3] The matches a coach has seen (live, the report, the replay, or the after-round window), so the window
// shows only those he missed.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('seen_matches', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('match_id')->constrained()->cascadeOnDelete();
            $table->timestamp('seen_at');
            $table->primary(['user_id', 'match_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seen_matches');
    }
};
