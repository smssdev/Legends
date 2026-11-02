{{--
  [Sprint 38 M1] Every email of Game Legend Manager in one frame: the game's colours (docs/design/tokens.json: ink #0A1F42,
  gold #F5B82E, chalk #F7F4EA), the name on top with «المدرب الأسطورة» under it in Arabic, and the team's word at the
  foot. Tables and inline styles only: what Gmail, Outlook and the phones' mail apps all show the same.
  Each email sets: $en (English or Arabic), and the sections title, preheader and body.
--}}
@php($dir = $en ? 'ltr' : 'rtl')
@php($align = $en ? 'left' : 'right')
@php($site = rtrim((string) config('app.url'), '/'))
<!DOCTYPE html>
<html lang="{{ $en ? 'en' : 'ar' }}" dir="{{ $dir }}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light">
<title>@yield('title')</title>
</head>
<body style="margin:0;padding:0;background:#EEF1F6;font-family:'Segoe UI',Tahoma,Arial,sans-serif;color:#0A1F42;">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;">@yield('preheader')</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#EEF1F6;padding:32px 12px;">
  <tr><td align="center">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 2px 12px rgba(10,31,66,0.08);" dir="{{ $dir }}">
      <tr><td style="background:#0A1F42;background-image:linear-gradient(135deg,#183349,#0A1F42 60%,#06111E);padding:22px 32px;text-align:{{ $align }};">
        <img src="{{ $site }}/icon-192.png" width="40" height="40" alt="" style="display:inline-block;width:40px;height:40px;border-radius:10px;vertical-align:middle;border:0;">
        <span style="display:inline-block;vertical-align:middle;padding:0 12px;">
          <span style="display:block;color:#F7F4EA;font-size:17px;font-weight:800;letter-spacing:1.5px;" dir="ltr">GAME LEGEND <span style="color:#F5B82E;">MANAGER</span></span>
          @unless($en)<span style="display:block;color:#C9D2E0;font-size:12px;font-weight:700;">المدرب الأسطورة · لعبة إدارة كرة القدم</span>@endunless
        </span>
      </td></tr>
      <tr><td style="height:4px;background:#F5B82E;line-height:4px;font-size:0;">&nbsp;</td></tr>
      @yield('body')
      <tr><td style="background:#F7F8FB;padding:16px 32px;text-align:center;font-size:12px;line-height:1.8;color:#8A96A8;">
        @hasSection('footer')@yield('footer')<br>@endif
        {{ $en ? 'The Game Legend Manager team' : 'فريق Game Legend Manager · المدرب الأسطورة' }}<br>
        <a href="{{ $site }}" style="color:#8A96A8;" dir="ltr">{{ parse_url($site, PHP_URL_HOST) ?: $site }}</a>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
