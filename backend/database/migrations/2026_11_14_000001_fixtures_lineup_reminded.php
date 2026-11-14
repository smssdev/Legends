<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** [Sprint 64 B5] "Is your lineup ready?" an hour before kick-off, once per fixture. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('fixtures', function (Blueprint $t) {
            $t->timestamp('lineup_reminded_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('fixtures', function (Blueprint $t) {
            $t->dropColumn('lineup_reminded_at');
        });
    }
};
