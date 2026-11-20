<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::forceCreate([
            'name' => 'سارة', 'email' => 'sara@example.com',
            'role' => 'admin', 'password' => 'sara-password-2026',
        ]);
        User::forceCreate([
            'name' => 'عمر', 'email' => 'omar@example.com',
            'role' => 'customer', 'password' => 'omar-password-2026',
        ]);
        DB::table('products')->insert([
            ['name' => 'عدة الروبوت', 'price' => 45000],
            ['name' => 'عجلات احتياطية', 'price' => 6000],
        ]);
    }
}
