<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Accounts [PLAN 2.17, 2.22]: a role, the Google account a user signed in with, a password that a
// Google-only account does not have, and one row of activity per user per day.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable()->change();
            $table->string('role', 16)->default('user')->after('password');
            $table->string('google_id')->nullable()->unique()->after('role');
        });

        Schema::create('user_activity', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('day');
            $table->unsignedInteger('logins')->default(0);
            $table->unsignedInteger('matches_watched')->default(0);
            $table->unsignedInteger('orders')->default(0);
            $table->primary(['user_id', 'day']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_activity');
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['google_id']);
            $table->dropColumn(['role', 'google_id']);
        });
    }
};
