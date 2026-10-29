<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [Sprint 21 E7] The admin panel's tools: a suspended account, the announcements as sent (sender and time), the
// developers' conversations with the coaches, and a log of what an admin did to an account.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('suspended_at')->nullable();
            $table->string('suspended_reason', 300)->nullable();
        });
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('title', 120);
            $table->text('body');
            $table->unsignedInteger('sent')->default(0);
            $table->timestamp('created_at');
        });
        Schema::create('support_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();            // the coach of the conversation
            $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();   // set when a developer wrote it
            $table->text('body');
            $table->timestamp('read_at')->nullable();
            $table->timestamp('created_at');
            $table->index(['user_id', 'id']);
        });
        Schema::create('admin_log', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action', 20);
            $table->unsignedBigInteger('target_user_id')->nullable();
            $table->string('details', 300)->nullable();
            $table->timestamp('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_log');
        Schema::dropIfExists('support_messages');
        Schema::dropIfExists('announcements');
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['suspended_at', 'suspended_reason']);
        });
    }
};
