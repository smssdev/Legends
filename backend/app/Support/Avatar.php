<?php

namespace App\Support;

/**
 * An account's picture [X4, 2026-10-24]: any image cut to its middle square and made a small JPEG, so the database
 * keeps a few kilobytes and never the file as it came (nor what it may hide).
 */
class Avatar
{
    /** The JPEG bytes, or null when the bytes are not an image GD reads. */
    public static function square(string $bytes, int $size): ?string
    {
        $src = @imagecreatefromstring($bytes);
        if ($src === false) {
            return null;
        }
        $w = imagesx($src);
        $h = imagesy($src);
        $side = min($w, $h);
        $out = imagecreatetruecolor($size, $size);
        // A transparent picture sits on white, not black.
        imagefill($out, 0, 0, imagecolorallocate($out, 255, 255, 255));
        imagecopyresampled($out, $src, 0, 0, intdiv($w - $side, 2), intdiv($h - $side, 2), $size, $size, $side, $side);
        ob_start();
        imagejpeg($out, null, 85);
        $jpeg = (string) ob_get_clean();
        imagedestroy($src);
        imagedestroy($out);

        return $jpeg;
    }

    /**
     * [X54] An announcement's wide picture: its own shape kept, at most $width wide and $maxHeight high, as a JPEG
     * (never the file as it came). Null when the bytes are not an image GD reads.
     */
    public static function wide(string $bytes, int $width, int $maxHeight): ?string
    {
        $src = @imagecreatefromstring($bytes);
        if ($src === false) {
            return null;
        }
        [$w, $h] = [imagesx($src), imagesy($src)];
        $scale = min(1, $width / $w, $maxHeight / $h);
        [$nw, $nh] = [max(1, (int) round($w * $scale)), max(1, (int) round($h * $scale))];
        $out = imagecreatetruecolor($nw, $nh);
        imagefill($out, 0, 0, imagecolorallocate($out, 255, 255, 255));
        imagecopyresampled($out, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        ob_start();
        imagejpeg($out, null, 82);
        $jpeg = (string) ob_get_clean();
        imagedestroy($src);
        imagedestroy($out);

        return $jpeg;
    }

    /**
     * [Sprint 43 W2] A store picture: cut to the middle of exactly $width × $height (one size in every card and email),
     * as a JPEG. Null when the bytes are not an image GD reads.
     */
    public static function cover(string $bytes, int $width, int $height): ?string
    {
        $src = @imagecreatefromstring($bytes);
        if ($src === false) {
            return null;
        }
        [$w, $h] = [imagesx($src), imagesy($src)];
        // The largest piece of the picture in the wanted shape, from its middle.
        [$cw, $ch] = $w * $height > $h * $width ? [intdiv($h * $width, $height), $h] : [$w, intdiv($w * $height, $width)];
        $out = imagecreatetruecolor($width, $height);
        imagefill($out, 0, 0, imagecolorallocate($out, 255, 255, 255));
        imagecopyresampled($out, $src, 0, 0, intdiv($w - $cw, 2), intdiv($h - $ch, 2), $width, $height, max(1, $cw), max(1, $ch));
        ob_start();
        imagejpeg($out, null, 84);
        $jpeg = (string) ob_get_clean();
        imagedestroy($src);
        imagedestroy($out);

        return $jpeg;
    }
}
