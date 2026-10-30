<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X61 E9] When a press statement was judged by the match's result (its morale stake applied once).
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('press_statements', function (Blueprint $table) {
            $table->timestamp('judged_at')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('press_statements', function (Blueprint $table) {
            $table->dropColumn('judged_at');
        });
    }
};
