<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** The pre-match scenarios [X23]: kept with the club's tactics, and frozen with its sheet at the lock. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tactics', fn (Blueprint $t) => $t->json('scenarios')->nullable());
        Schema::table('fixture_sheets', fn (Blueprint $t) => $t->json('scenarios')->nullable());
    }

    public function down(): void
    {
        Schema::table('tactics', fn (Blueprint $t) => $t->dropColumn('scenarios'));
        Schema::table('fixture_sheets', fn (Blueprint $t) => $t->dropColumn('scenarios'));
    }
};
