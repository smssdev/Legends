<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 68] More of the game's bot: per link, whether the coach's own live matches reach him (a goal, a red card,
 * half-time, the result) and the Cairo hour of his daily summary (and the day it was last sent, so it goes once); per
 * league group, whether its matches' goals are posted live; and the polls posted before each round, to settle with
 * the result.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messenger_links', function (Blueprint $t) {
            $t->boolean('live')->default(true);
            $t->unsignedTinyInteger('daily_hour')->nullable();
            $t->date('daily_sent_on')->nullable();
        });
        Schema::table('messenger_groups', function (Blueprint $t) {
            $t->boolean('live')->default(true);
        });
        Schema::create('messenger_polls', function (Blueprint $t) {
            $t->id();
            $t->foreignId('group_id')->constrained('messenger_groups')->cascadeOnDelete();
            $t->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $t->string('chat_id', 64);
            $t->unsignedBigInteger('message_id');
            $t->timestamp('settled_at')->nullable();
            $t->timestamp('created_at');
            $t->unique(['group_id', 'fixture_id']);
            $t->index('fixture_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('messenger_polls');
        Schema::table('messenger_groups', fn (Blueprint $t) => $t->dropColumn('live'));
        Schema::table('messenger_links', fn (Blueprint $t) => $t->dropColumn(['live', 'daily_hour', 'daily_sent_on']));
    }
};
