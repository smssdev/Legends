<?php

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use League\Flysystem\PathTraversalDetected;

Route::get('unsafe/products', function (Request $request) {
    $q = $request->query('q');

    // DANGER: the input becomes part of the SQL text
    return DB::select("SELECT name, price FROM products WHERE name = '$q'");
});

Route::get('products', function (Request $request) {
    $q = $request->validate(['q' => ['required', 'string', 'max:100']])['q'];

    // the input travels separately, as a binding: it is only ever a value
    // the same query with Eloquent: Product::where('name', $q)->get()
    return DB::select('SELECT name, price FROM products WHERE name = ?', [$q]);
});

Route::patch('unsafe/users/{user}', function (Request $request, User $user) {
    // DANGER: every field the client sends is written, role included
    $user->forceFill($request->all())->save();

    return $user->only('id', 'name', 'role');
});

Route::patch('users/{user}', function (Request $request, User $user) {
    // only the fields a customer may change; role is refused outright
    $user->update($request->validate([
        'name' => ['required', 'string', 'max:100'],
        'role' => ['prohibited'],
    ]));

    return $user->only('id', 'name', 'role');
});

Route::get('unsafe/files/{path}', function (string $path) {
    // DANGER: '../' climbs out of the folder
    $text = file_get_contents(storage_path("app/files/$path"));

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

Route::get('files/{path}', function (string $path) {
    // a disk rooted at the folder: Flysystem refuses paths that climb out
    $files = Storage::build(['driver' => 'local', 'root' => storage_path('app/files')]);
    try {
        $text = $files->get($path) ?? abort(404, 'Not Found');
    } catch (PathTraversalDetected) {
        abort(404, 'Not Found');
    }

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

// a query that fails, to see what an error reveals
Route::get('boom', fn () => DB::select('SELECT * FROM missing_table'));
