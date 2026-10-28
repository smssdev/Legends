<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// [Sprint 21 E2] Every account's own five-digit number (instead of 1, 2...), who invited it, and the email a
// verification code was sent to with its wrong tries. Existing accounts get their number here.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->unsignedInteger('account_no')->nullable()->unique();
            $table->foreignId('referred_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('referral_paid_at')->nullable();
        });
        Schema::table('account_codes', function (Blueprint $table) {
            $table->string('email', 190)->nullable();
            $table->unsignedSmallInteger('attempts')->default(0);
        });
        $taken = [];
        foreach (DB::table('users')->whereNull('account_no')->orderBy('id')->pluck('id') as $id) {
            do {
                $no = random_int(10000, 99999);
            } while (isset($taken[$no]));
            $taken[$no] = true;
            DB::table('users')->where('id', $id)->update(['account_no' => $no]);
        }
    }

    public function down(): void
    {
        Schema::table('account_codes', function (Blueprint $table) {
            $table->dropColumn(['email', 'attempts']);
        });
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('referred_by');
            $table->dropUnique(['account_no']);
            $table->dropColumn(['account_no', 'referral_paid_at']);
        });
    }
};
