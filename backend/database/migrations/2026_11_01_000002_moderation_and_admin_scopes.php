<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 30 G6] The groups' moderation: a coach's report on a message (one per coach and message), decided by an admin
 * (left, removed, or removed and its writer kept out of the groups: users.chat_banned_at). And the admins' scopes
 * (users.admin_scope): support, content or finance; empty is a full admin. Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chat_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('chat_group_message_id')->constrained()->cascadeOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->string('reason', 20);                       // abuse, inappropriate, spam, other
            $table->string('note', 300)->nullable();
            $table->string('status', 10)->default('pending');   // pending, kept, removed, banned
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('decided_at')->nullable();
            $table->timestamp('created_at');
            $table->unique(['chat_group_message_id', 'reporter_id']);
            $table->index(['status', 'id']);
        });
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('chat_banned_at')->nullable();
            $table->string('admin_scope', 10)->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_reports');
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn(['chat_banned_at', 'admin_scope']));
    }
};
