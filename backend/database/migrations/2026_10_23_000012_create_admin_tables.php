<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The admin panel [PLAN 2.17, 2.22, Sprint 37]: the two-step code's secret of an admin, and the visits counted in
 * the activity log (Sprint 10's user_activity) for the activity and return indicators.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('two_factor_secret')->nullable();   // encrypted
            $table->timestamp('two_factor_enabled_at')->nullable();
        });
        Schema::table('user_activity', function (Blueprint $table) {
            $table->unsignedInteger('visits')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('user_activity', fn (Blueprint $table) => $table->dropColumn('visits'));
        Schema::table('users', fn (Blueprint $table) => $table->dropColumn(['two_factor_secret', 'two_factor_enabled_at']));
    }
};
