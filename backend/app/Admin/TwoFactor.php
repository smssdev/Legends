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

    /** @return list<string> the recovery codes, shown once (Sprint 30 Q11) */
    public static function confirm(User $user, string $code): array
    {
        self::check($user, $code);
        $user->forceFill(['two_factor_enabled_at' => GameClock::now()])->save();
        session([self::SESSION => GameClock::now()->timestamp]);

        return self::newRecovery($user);
    }

    /**
     * [Sprint 30 Q11] Eight one-time codes for a lost phone (xxxxx-xxxxx), kept as their hashes only: each opens the
     * panel once in place of the six digits. New ones replace all the old.
     *
     * @return list<string>
     */
    public static function newRecovery(User $user): array
    {
        $codes = array_map(fn () => strtolower(substr(bin2hex(random_bytes(5)), 0, 5).'-'.substr(bin2hex(random_bytes(5)), 0, 5)), range(1, 8));
        $user->forceFill(['two_factor_recovery' => json_encode(array_map(fn ($c) => hash('sha256', $c), $codes))])->save();

        return $codes;
    }

    public static function recoveryLeft(User $user): int
    {
        return count(json_decode((string) $user->two_factor_recovery, true) ?: []);
    }

    public static function verify(User $user, string $code): void
    {
        if (! $user->two_factor_enabled_at) {
            throw new HttpException(409, 'فعّل التحقق بخطوتين أولاً.');
        }
        self::check($user, $code);
        session([self::SESSION => GameClock::now()->timestamp]);
    }

    /** [X46] Whether the panel asks for the code at all (game.admin.two_factor). */
    public static function required(): bool
    {
        return (bool) config('game.admin.two_factor');
    }

    /** This session proved the code within the last hours, or the panel does not ask for it. */
    public static function passed(): bool
    {
        if (! self::required()) {
            return true;
        }
        $at = (int) session(self::SESSION, 0);

        return $at && GameClock::now()->timestamp - $at < (int) config('game.admin.two_factor_hours') * 3600;
    }

    private static function check(User $user, string $code): void
    {
        // [Sprint 30 Q11] A recovery code (letters and a dash): once, then it is gone.
        if (preg_match('/^[a-f0-9]{5}-[a-f0-9]{5}$/', $c = strtolower(trim($code))) === 1) {
            $left = json_decode((string) $user->two_factor_recovery, true) ?: [];
            $at = array_search(hash('sha256', $c), $left, true);
            if ($at === false) {
                throw new HttpException(422, 'رمز الاسترداد غير صحيح أو استُعمل من قبل.');
            }
            unset($left[$at]);
            $user->forceFill(['two_factor_recovery' => json_encode(array_values($left))])->save();

            return;
        }
        $secret = $user->two_factor_secret ? decrypt($user->two_factor_secret) : null;
        if (! $secret || ! self::engine()->verifyKey($secret, preg_replace('/\D/', '', $code), 1)) {
            throw new HttpException(422, 'الرمز غير صحيح أو انتهى وقته.');
        }
    }
}
