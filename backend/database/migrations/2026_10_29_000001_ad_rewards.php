<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 21 E9] Each rewarded video that cut a task's time: whose, which task, and the provider's own reward id,
// unique, so the same video never counts twice.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ad_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('item', 20);                 // training | stadium
            $table->unsignedBigInteger('item_id');      // the training slot or the stadium part being built
            $table->string('provider', 30);
            $table->string('reward_id', 190);           // the provider's id for this one watched video
            $table->unsignedInteger('minutes');
            $table->timestamp('created_at');
            $table->unique(['provider', 'reward_id']);
            $table->index(['item', 'item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ad_rewards');
    }
};
