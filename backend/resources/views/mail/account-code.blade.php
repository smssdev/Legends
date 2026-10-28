{{-- The verification code email [Sprint 21 E2.4]. Tables and inline styles: what every mail app (Gmail, Outlook, phones) shows the same. --}}
@php($dir = $en ? 'ltr' : 'rtl')
@php($align = $en ? 'left' : 'right')
<!DOCTYPE html>
<html lang="{{ $en ? 'en' : 'ar' }}" dir="{{ $dir }}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<title>{{ $en ? 'Your verification code' : 'كود توثيق حسابك' }}</title>
</head>
<body style="margin:0;padding:0;background:#EEF1F6;font-family:'Segoe UI',Tahoma,Arial,sans-serif;color:#0A1F42;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">{{ $en ? "Your code: {$code}. Valid for {$minutes} minutes." : "كودك: {$code}. صالح {$minutes} دقيقة." }}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF1F6;padding:32px 12px;">
  <tr><td align="center">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(10,31,66,0.08);" dir="{{ $dir }}">
      <tr><td style="background:#0A1F42;padding:24px 32px;text-align:{{ $align }};">
        <span style="display:inline-block;width:36px;height:36px;line-height:36px;border-radius:10px;background:#F5B82E;color:#0A1F42;font-weight:800;font-size:18px;text-align:center;vertical-align:middle;">G</span>
        <span style="color:#F7F4EA;font-size:18px;font-weight:700;vertical-align:middle;padding:0 10px;">{{ $en ? 'Game Legend Manager' : 'لعبة المدرب الأسطورة' }}</span>
      </td></tr>
      <tr><td style="padding:32px 32px 8px;text-align:{{ $align }};">
        <h1 style="margin:0 0 12px;font-size:22px;line-height:1.4;color:#0A1F42;">{{ $en ? 'Verify your account' : 'وثّق حسابك' }}</h1>
        <p style="margin:0;font-size:15px;line-height:1.8;color:#3B4A63;">
          {{ $en ? "Hello {$name}, use this code to verify your account" : "أهلاً {$name}، استخدم هذا الكود لتوثيق حسابك" }}
          <span dir="ltr" style="color:#0A1F42;font-weight:600;">&#64;{{ $username }}</span>@if($accountNo) <span style="color:#6B7A90;">({{ $en ? 'account' : 'رقم الحساب' }} <span dir="ltr">{{ $accountNo }}</span>)</span>@endif.
        </p>
      </td></tr>
      <tr><td align="center" style="padding:24px 32px;">
        <div dir="ltr" style="display:inline-block;background:#F7F4EA;border:1px solid #F5B82E;border-radius:12px;padding:16px 28px;font-family:'Courier New',monospace;font-size:36px;font-weight:700;letter-spacing:10px;color:#0A1F42;">{{ $code }}</div>
        <p style="margin:12px 0 0;font-size:13px;color:#6B7A90;">{{ $en ? "Valid for {$minutes} minutes, and only once." : "صالح {$minutes} دقيقة، ولمرة واحدة فقط." }}</p>
      </td></tr>
      <tr><td align="center" style="padding:0 32px 28px;">
        <a href="{{ $url }}" style="display:inline-block;background:#F5B82E;color:#0A1F42;text-decoration:none;font-weight:700;font-size:15px;padding:12px 28px;border-radius:10px;">{{ $en ? 'Open my account' : 'افتح حسابي' }}</a>
      </td></tr>
      <tr><td style="padding:0 32px 28px;text-align:{{ $align }};">
        <div style="border-top:1px solid #E3E7EE;padding-top:16px;font-size:13px;line-height:1.8;color:#6B7A90;">
          {{ $en ? 'Never share this code with anyone. The game\'s team will never ask you for it.' : 'لا تشارك هذا الكود مع أحد. فريق اللعبة لن يطلبه منك أبداً.' }}<br>
          {{ $en ? 'If you did not ask for it, ignore this email: your account stays as it is.' : 'إن لم تطلبه فتجاهل هذه الرسالة، وحسابك يبقى كما هو.' }}
        </div>
      </td></tr>
      <tr><td style="background:#F7F8FB;padding:16px 32px;text-align:center;font-size:12px;color:#8A96A8;">
        {{ $en ? 'Game Legend Manager · the team' : 'فريق لعبة المدرب الأسطورة' }}
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
