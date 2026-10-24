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
}
