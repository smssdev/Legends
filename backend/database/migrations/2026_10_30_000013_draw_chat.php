<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [X66] What the viewers of a live draw say while it runs: a line or an emoji reaction, kept so a replay shows them
 * at the moment they came. Deleted with the chat groups' messages after the admin's retention.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('draw_chat', function (Blueprint $t) {
            $t->id();
            $t->foreignId('league_id')->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $t->string('kind', 8);
            $t->string('body', 300);
            $t->timestamp('created_at')->nullable();
            $t->timestamp('deleted_at')->nullable();
            $t->index(['league_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('draw_chat');
    }
};
