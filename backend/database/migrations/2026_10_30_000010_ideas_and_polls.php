<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 28] The coaches' suggestions to the developers (with the team's answer and its reward), and the polls on
// what to build next: each poll's options and each account's one vote.
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('suggestions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title', 120);
            $table->text('body');
            $table->string('status', 10)->default('pending');   // pending, accepted, built, rejected
            $table->unsignedInteger('coins')->default(0);         // the reward given, once
            $table->string('reply', 500)->nullable();             // the team's word to the coach
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'id']);
            $table->index(['user_id', 'id']);
        });
        Schema::create('polls', function (Blueprint $table) {
            $table->id();
            $table->string('question', 160);
            $table->text('body')->nullable();
            $table->timestamp('starts_at');
            $table->timestamp('ends_at');
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
            $table->index('ends_at');
        });
        Schema::create('poll_options', function (Blueprint $table) {
            $table->id();
            $table->foreignId('poll_id')->constrained()->cascadeOnDelete();
            $table->string('label', 120);
            $table->foreignId('suggestion_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedSmallInteger('position')->default(0);
        });
        Schema::create('poll_votes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('poll_id')->constrained()->cascadeOnDelete();
            $table->foreignId('option_id')->constrained('poll_options')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['poll_id', 'user_id']);
            $table->index('option_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('poll_votes');
        Schema::dropIfExists('poll_options');
        Schema::dropIfExists('polls');
        Schema::dropIfExists('suggestions');
    }
};
