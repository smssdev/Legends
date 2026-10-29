<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 20 B5] The weekly quests a club has claimed: once each a week.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quest_claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->date('week');                // the Monday (Cairo) the week began
            $table->string('quest', 20);
            $table->timestamp('claimed_at');
            $table->unique(['club_id', 'week', 'quest']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('quest_claims');
    }
};
