<?php

namespace App\Models;

use App\Notifications\ResetPasswordNotice;
use App\Notifications\VerifyEmailNotice;
use Database\Factories\UserFactory;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * A player's account [PLAN 2.17]: email and password, Google, or both. The same account
 * signs in on the web (Sanctum session cookie) and in the app (a token that expires).
 */
class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLES = ['user', 'admin'];

    /** @var list<string> */
    protected $fillable = ['name', 'email', 'password', 'google_id'];

    /** @var list<string> */
    protected $hidden = ['password', 'remember_token', 'google_id'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function hasPassword(): bool
    {
        return $this->password !== null;
    }

    /** What the API shows of the account: never the password, the Google id or the remember token. */
    public function toAccount(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified' => $this->hasVerifiedEmail(),
            'role' => $this->role,
            'has_password' => $this->hasPassword(),
            'google' => $this->google_id !== null,
            'created_at' => $this->created_at?->toIso8601ZuluString(),
        ];
    }

    public function sendEmailVerificationNotification(): void
    {
        $this->notify(new VerifyEmailNotice);
    }

    public function sendPasswordResetNotification(#[\SensitiveParameter] $token): void
    {
        $this->notify(new ResetPasswordNotice($token));
    }
}
