<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [UP13] The owner's spec (7, 2026-10-26): an account's holidays with their days and reason (up to 5 days at once
 * and on its own, longer ones decided by the developers), and the warning before an inactive account is deleted.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('account_vacations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('days');
            $table->string('reason', 300);
            $table->string('status', 10);   // auto, pending, approved, rejected
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('decided_at')->nullable();
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'status']);
        });
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('inactive_warned_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('account_vacations');
        Schema::table('users', fn (Blueprint $t) => $t->dropColumn('inactive_warned_at'));
    }
};
