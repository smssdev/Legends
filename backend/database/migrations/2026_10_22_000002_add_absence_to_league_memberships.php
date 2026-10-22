<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// The absence warning [PLAN 2.2]: when the 48-hour notice went out for the current quiet stretch.
// Any activity clears it, so the next quiet stretch warns again.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('league_memberships', function (Blueprint $table) {
            $table->timestamp('absence_warned_at')->nullable()->after('last_active_at');
        });
    }

    public function down(): void
    {
        Schema::table('league_memberships', fn (Blueprint $table) => $table->dropColumn('absence_warned_at'));
    }
};
