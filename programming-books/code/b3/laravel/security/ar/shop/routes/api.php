<?php

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use League\Flysystem\PathTraversalDetected;

Route::get('unsafe/products', function (Request $request) {
    $q = $request->query('q');

    // خطر: المدخل يصير جزءاً من نص SQL
    return DB::select("SELECT name, price FROM products WHERE name = '$q'");
});

Route::get('products', function (Request $request) {
    $q = $request->validate(['q' => ['required', 'string', 'max:100']])['q'];

    // المدخل يسافر منفصلاً، بصفة ربط: لا يكون إلا قيمة
    // الاستعلام نفسه بـ Eloquent: Product::where('name', $q)->get()
    return DB::select('SELECT name, price FROM products WHERE name = ?', [$q]);
});

Route::patch('unsafe/users/{user}', function (Request $request, User $user) {
    // خطر: كل حقل يرسله العميل يُكتب، والدور معه
    $user->forceFill($request->all())->save();

    return $user->only('id', 'name', 'role');
});

Route::patch('users/{user}', function (Request $request, User $user) {
    // الحقول التي يجوز للزبون تغييرها وحدها؛ والدور مرفوض صراحة
    $user->update($request->validate([
        'name' => ['required', 'string', 'max:100'],
        'role' => ['prohibited'],
    ]));

    return $user->only('id', 'name', 'role');
});

Route::get('unsafe/files/{path}', function (string $path) {
    // خطر: '../' تصعد خارج المجلد
    $text = file_get_contents(storage_path("app/files/$path"));

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

Route::get('files/{path}', function (string $path) {
    // قرص جذره المجلد: Flysystem ترفض المسارات التي تصعد خارجه
    $files = Storage::build(['driver' => 'local', 'root' => storage_path('app/files')]);
    try {
        $text = $files->get($path) ?? abort(404, 'Not Found');
    } catch (PathTraversalDetected) {
        abort(404, 'Not Found');
    }

    return response($text)->header('Content-Type', 'text/plain');
})->where('path', '.*');

// استعلام يفشل، لنرى ما يكشفه الخطأ
Route::get('boom', fn () => DB::select('SELECT * FROM missing_table'));
