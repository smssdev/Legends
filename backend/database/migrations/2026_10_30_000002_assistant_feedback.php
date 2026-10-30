<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X61] The coach's rating of the Assistant Coach at the end of a conversation: helpful or not, the page, and an
// optional short note (in the privacy policy). Not the conversation itself.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('assistant_feedback', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->boolean('helpful');
            $table->string('page', 40)->nullable();
            $table->string('note', 300)->nullable();
            $table->timestamp('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assistant_feedback');
    }
};
