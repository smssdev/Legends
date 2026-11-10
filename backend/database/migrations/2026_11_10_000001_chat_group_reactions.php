<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** [Sprint 50 M8] A member's one reaction on a group message (tapped again, taken back). */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_group_reactions', function (Blueprint $t) {
            $t->id();
            $t->foreignId('chat_group_message_id')->constrained()->cascadeOnDelete();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('reaction', 8);
            $t->timestamp('created_at')->nullable();
            $t->unique(['chat_group_message_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_group_reactions');
    }
};
