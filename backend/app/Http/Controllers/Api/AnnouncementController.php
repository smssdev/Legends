<?php

namespace App\Http\Controllers\Api;

use App\Admin\Announcements;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

/** [X54] The developers' announcements for every coach: the cards, newest first, and each card's picture. */
class AnnouncementController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json(['announcements' => Announcements::list()]);
    }

    public function image(int $id): Response
    {
        $image = DB::table('announcement_images')->where('announcement_id', $id)->value('image');
        abort_unless($image !== null, 404);

        return response($image, 200, ['Content-Type' => 'image/jpeg', 'Cache-Control' => 'public, max-age=604800, immutable']);
    }
}
