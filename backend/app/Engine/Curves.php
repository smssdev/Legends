<?php

namespace App\Engine;

/**
 * [Sprint 49] The match's S-curves in integers (the engine has no floats, CLAUDE.md): tanh and the logistic, read from a
 * table at steps of 0.1 and joined by straight lines between them. In and out are in units of 1/10000 (bp): x = 1.5 is
 * 15000, tanh(1.5) = 0.9051 is 9051. The same everywhere, so a match plays the same on any machine.
 */
final class Curves
{
    /** tanh(k / 10) × 10000 for k = 0..30; beyond 3 it is 1 within half a per cent. */
    private const TANH = [0, 997, 1974, 2913, 3799, 4621, 5370, 6044, 6640, 7163, 7616, 8005, 8337, 8617, 8854, 9051,
        9217, 9354, 9468, 9562, 9640, 9705, 9757, 9801, 9837, 9866, 9890, 9910, 9926, 9940, 9951];

    /** tanh(x) in bp, x in bp: −10000..10000. */
    public static function tanh(int $x): int
    {
        if ($x < 0) {
            return -self::tanh(-$x);
        }
        $k = intdiv($x, 1000);
        if ($k >= 30) {
            return 9951 + intdiv(min($x - 30000, 10000) * 49, 10000);
        }
        $from = self::TANH[$k];

        return $from + intdiv((self::TANH[$k + 1] - $from) * ($x % 1000), 1000);
    }

    /** The logistic 1 / (1 + e^−x) in bp, x in bp: 0..10000 (it is ½ + ½·tanh(x / 2)). */
    public static function logistic(int $x): int
    {
        return 5000 + intdiv(self::tanh(intdiv($x, 2)), 2);
    }

    /**
     * The share of the ball one side has in a zone [Sprint 49, the owner's guide 6.1.2]: ½ + ½·tanh(gap / scale), with
     * the gap and the scale in the same units (rating centi-points). Equal sides 5000; a side far better nears 10000.
     */
    public static function share(int $gap, int $scale): int
    {
        return 5000 + intdiv(self::tanh(intdiv($gap * 10000, max(1, $scale))), 2);
    }
}
