<?php
// The page Render shows while the saved game cannot be read from B2 (deploy/render/start.sh, X39): every address
// answers 200, so Render keeps the service up, and nobody plays a game that would not be saved. start.sh retries B2
// every 10 minutes and puts the game back in its place once it answers.
http_response_code(200);
if (str_starts_with($_SERVER['REQUEST_URI'] ?? '/', '/api/')) {
    header('Content-Type: application/json; charset=utf-8');
    header('Retry-After: 600');
    echo json_encode(['message' => 'اللعبة في صيانة قصيرة، وتعود خلال دقائق.', 'code' => 'maintenance'], JSON_UNESCAPED_UNICODE);

    return true;
}
header('Content-Type: text/html; charset=utf-8');
?><!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="120"><title>الأساطير: صيانة قصيرة</title>
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#06111E;color:#F7F4EA;font-family:system-ui,sans-serif;text-align:center;padding:24px}
.box{max-width:420px;padding:28px;border-radius:18px;background:#0D2133;border-top:4px solid #12A07E}h1{color:#F5B82E;margin:0 0 12px}p{color:#C9D2E1;line-height:1.7}</style></head>
<body><div class="box"><h1>صيانة قصيرة</h1><p>نحفظ دوريك ونعيده إلى مكانه. اللعبة تعود وحدها خلال دقائق، وكل ما لعبته محفوظ.</p><p>هذه الصفحة تتحدث تلقائياً.</p></div></body></html>
