<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// [X57] Which ad a watch was: the game's own (house) or Google's rewarded video (adsense), for the owner's count.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ad_watches', function (Blueprint $table) {
            $table->string('provider', 16)->default('house');
        });
    }

    public function down(): void
    {
        Schema::table('ad_watches', function (Blueprint $table) {
            $table->dropColumn('provider');
        });
    }
};
