<?php

namespace App\Models;

use App\Auth\Username;
use App\Notifications\ResetPasswordNotice;
use App\Notifications\VerifyEmailNotice;
use App\Support\GameClock;
use Database\Factories\UserFactory;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
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
    protected $fillable = ['name', 'username', 'email', 'password', 'google_id', 'commentator', 'match_view'];

    /** @var list<string> */
    protected $hidden = ['password', 'remember_token', 'google_id', 'two_factor_secret'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'vacation_from' => 'datetime',
            'vacation_until' => 'datetime',
        ];
    }

    /** Every account has a username [X4]: one made without it (Google, a test) gets a free one from its email. */
    protected static function booted(): void
    {
        static::creating(function (User $user) {
            $user->username = $user->username ? strtolower($user->username) : Username::free(strtok((string) $user->email, '@') ?: (string) $user->name);
        });
    }

    /** The account's holiday [X4]: every league it coaches in stops counting its absence meanwhile. */
    public function onVacation(?Carbon $at = null): bool
    {
        $at ??= GameClock::now();

        return $this->vacation_from !== null && $this->vacation_from->lte($at) && $this->vacation_until->gt($at);
    }

    /** The picture's address, with its time so a new one is not taken from the cache; null without one. */
    public function avatarUrl(): ?string
    {
        $at = DB::table('user_avatars')->where('user_id', $this->id)->value('updated_at');

        return $at ? '/api/v1/users/'.$this->id.'/avatar?v='.strtotime($at) : null;
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
            'username' => $this->username,
            // The developers' accounts carry the official badge everywhere [X11].
            'official' => Username::official($this->username),
            'avatar_url' => $this->avatarUrl(),
            'email' => $this->email,
            'email_verified' => $this->hasVerifiedEmail(),
            'role' => $this->role,
            'has_password' => $this->hasPassword(),
            'google' => $this->google_id !== null,
            'created_at' => $this->created_at?->toIso8601ZuluString(),
            // How the coach watches [X9, X10]: the same on every device.
            'viewing' => [
                'commentator' => $this->commentator ?? config('game.viewing.default_commentator'),
                'match_view' => $this->match_view ?? 'cartoon',
                'unity_ready' => (bool) config('game.viewing.unity_ready'),
            ],
            'vacation' => [
                'on' => $this->onVacation(),
                'until' => $this->vacation_until?->toIso8601ZuluString(),
                // A new holiday once the last one has ended and the rest days after it have passed.
                'next_from' => $this->vacation_until?->copy()->addDays((int) config('game.account.vacation_rest_days'))->toIso8601ZuluString(),
                'max_days' => (int) config('game.account.vacation_max_days'),
            ],
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
