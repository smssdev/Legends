<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // زبونان لهما طلبات، ومدير (كلمات مرور للتطوير فقط)
        $people = [
            ['sara@example.com', 'سارة', 'customer', [45000, 6000]],
            ['omar@example.com', 'عمر', 'customer', [12000]],
            ['admin@example.com', 'المدير', 'admin', []],
        ];
        foreach ($people as [$email, $name, $role, $totals]) {
            $user = User::forceCreate([
                'email' => $email,
                'name' => $name,
                'role' => $role,
                'password' => strtok($email, '@').'-password-2026',
            ]);
            foreach ($totals as $total) {
                $user->orders()->create(['total' => $total]);
            }
        }
    }
}
