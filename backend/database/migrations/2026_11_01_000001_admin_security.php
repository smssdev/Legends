<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * [Sprint 30 Q11] The admins' security: the address each sensitive admin action came from (admin_log.ip), and the
 * one-time recovery codes for the two-step code (users.two_factor_recovery, their SHA-256 hashes only). Adds only.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('admin_log', function (Blueprint $table) {
            $table->string('ip', 45)->nullable();
        });
        Schema::table('users', function (Blueprint $table) {
            $table->text('two_factor_recovery')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('admin_log', fn (Blueprint $table) => $table->dropColumn('ip'));
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn('two_factor_recovery'));
    }
};
