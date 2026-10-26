<?php

namespace App\Admin;

use App\Models\User;
use App\Support\GameClock;
use PragmaRX\Google2FA\Google2FA;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The admin's second step [PLAN 2.17, Sprint 37]: a six-digit code from an authenticator app (TOTP, free, no
 * service). Set up once; then every admin session proves it again before the panel opens, for some hours.
 */
class TwoFactor
{
    private const SESSION = 'admin_2fa_at';

    public static function engine(): Google2FA
    {
        return new Google2FA;
    }

    /** A new secret to scan (kept until it is confirmed with a code). */
    public static function setup(User $user): array
    {
        if ($user->two_factor_enabled_at) {
            throw new HttpException(409, 'التحقق بخطوتين مفعّل من قبل.');
        }
        $secret = self::engine()->generateSecretKey(32);
        $user->forceFill(['two_factor_secret' => encrypt($secret)])->save();

        return ['secret' => $secret, 'uri' => self::engine()->getQRCodeUrl(config('game.brand.name_latin', 'Game Legend Manager'), $user->email, $secret)];
    }

    public static function confirm(User $user, string $code): void
    {
        self::check($user, $code);
        $user->forceFill(['two_factor_enabled_at' => GameClock::now()])->save();
        session([self::SESSION => GameClock::now()->timestamp]);
    }

    public static function verify(User $user, string $code): void
    {
        if (! $user->two_factor_enabled_at) {
            throw new HttpException(409, 'فعّل التحقق بخطوتين أولاً.');
        }
        self::check($user, $code);
        session([self::SESSION => GameClock::now()->timestamp]);
    }

    /** This session proved the code within the last hours. */
    public static function passed(): bool
    {
        $at = (int) session(self::SESSION, 0);

        return $at && GameClock::now()->timestamp - $at < (int) config('game.admin.two_factor_hours') * 3600;
    }

    private static function check(User $user, string $code): void
    {
        $secret = $user->two_factor_secret ? decrypt($user->two_factor_secret) : null;
        if (! $secret || ! self::engine()->verifyKey($secret, preg_replace('/\D/', '', $code), 1)) {
            throw new HttpException(422, 'الرمز غير صحيح أو انتهى وقته.');
        }
    }
}
