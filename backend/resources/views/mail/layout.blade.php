{{--
  [X80] The frame of every Game Legend Manager email, made like the big companies' mail: a 600px card on a soft grey,
  the logo on the game's navy, a hero for the email's one message, the body, one gold button, and a footer with the
  game's links and why the email came. Tables and inline styles only (Gmail, Outlook, Apple Mail and the phones show
  them the same), web-safe fonts, images with their size and alt text, and a dark look where the mail app has one.
  Each email sets $en and the sections: title, preheader, hero, body, and optionally footer (why it came).
  Colours from docs/design/tokens.json: ink #0A1F42, night #06111E, gold #F5B82E, chalk #F7F4EA.
--}}
@php($dir = $en ? 'ltr' : 'rtl')
@php($align = $en ? 'left' : 'right')
@php($site = rtrim((string) config('app.url'), '/'))
@php($host = parse_url($site, PHP_URL_HOST) ?: $site)
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
<!DOCTYPE html>
<html lang="{{ $en ? 'en' : 'ar' }}" dir="{{ $dir }}" xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="color-scheme" content="light dark">
<meta name="supported-color-schemes" content="light dark">
<meta name="format-detection" content="telephone=no, date=no, address=no, email=no">
<title>@yield('title')</title>
<style>
  body { margin:0 !important; padding:0 !important; width:100% !important; -webkit-text-size-adjust:100%; }
  table { border-collapse:collapse; }
  .glm-panel { border-collapse:separate !important; }
  img { border:0; outline:none; text-decoration:none; -ms-interpolation-mode:bicubic; }
  a { color:#B7860B; }
  @media only screen and (max-width:620px) {
    .glm-card { width:100% !important; border-radius:0 !important; }
    .glm-pad { padding-left:24px !important; padding-right:24px !important; }
    .glm-btn a { display:block !important; }
    .glm-hero-title { font-size:26px !important; }
    .glm-score { font-size:44px !important; }
  }
  @media (prefers-color-scheme: dark) {
    .glm-bg { background:#0B1220 !important; }
    .glm-card, .glm-body { background:#111A2E !important; }
    .glm-text { color:#D5DCE8 !important; }
    .glm-title { color:#FFFFFF !important; }
    .glm-muted { color:#98A4B8 !important; }
    .glm-panel { background:#16223A !important; border-color:#24324F !important; }
    .glm-foot { background:#0D1526 !important; }
    .glm-rule { border-color:#24324F !important; }
  }
</style>
</head>
<body class="glm-bg" style="margin:0;padding:0;background:#F2F4F8;font-family:{{ $font }};color:#0A1F42;">
{{-- What the inbox shows beside the subject, then spaces so the mail app adds nothing after it. --}}
<div style="display:none;max-height:0;max-width:0;overflow:hidden;opacity:0;mso-hide:all;font-size:1px;line-height:1px;color:#F2F4F8;">@yield('preheader')&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;&#8199;&#847;</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="glm-bg" style="background:#F2F4F8;">
  <tr><td align="center" style="padding:32px 12px 40px;">
    <table role="presentation" width="600" cellpadding="0" cellspacing="0" class="glm-card" style="width:600px;max-width:600px;background:#FFFFFF;border-radius:20px;overflow:hidden;border:1px solid #E4E8EF;" dir="{{ $dir }}">
      {{-- The logo on the game's navy. --}}
      <tr><td align="center" bgcolor="#0B1A2C" style="background:#0B1A2C;background-image:linear-gradient(135deg,#183349 0%,#0B1A2C 55%,#06111E 100%);padding:26px 24px 22px;">
        <a href="{{ $site }}" style="text-decoration:none;" target="_blank">
          <img src="{{ $site }}/brand/email-logo.png" width="280" height="39" alt="GAME LEGEND MANAGER" style="display:block;width:280px;height:39px;color:#FFFFFF;font:800 18px {{ $font }};letter-spacing:1px;">
        </a>
        @unless($en)<div style="font-family:{{ $font }};font-size:13px;line-height:20px;color:#AEB9CC;padding-top:8px;">المدرب الأسطورة · لعبة إدارة كرة القدم أونلاين</div>@endunless
      </td></tr>
      <tr><td height="4" bgcolor="#F5B82E" style="height:4px;line-height:4px;font-size:0;background:#F5B82E;background-image:linear-gradient(90deg,#FFD36B,#F5B82E,#C08A0C);">&nbsp;</td></tr>
      @yield('hero')
      <tr><td class="glm-body" style="background:#FFFFFF;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">@yield('body')</table>
      </td></tr>
      {{-- The footer: the game's links, why the email came, and the game's line. --}}
      <tr><td class="glm-foot glm-pad" style="background:#F7F8FB;padding:28px 40px 30px;text-align:center;font-family:{{ $font }};">
        <img src="{{ $site }}/icon-192.png" width="36" height="36" alt="" style="display:inline-block;width:36px;height:36px;border-radius:9px;">
        <div class="glm-muted" style="font-size:13px;line-height:22px;color:#667085;padding-top:12px;">
          <a href="{{ $site }}" style="color:#475467;text-decoration:none;font-weight:600;" target="_blank">{{ $en ? 'Play' : 'العب الآن' }}</a>
          &nbsp;·&nbsp; <a href="{{ $site }}/guide{{ $en ? '?lang=en' : '' }}" style="color:#475467;text-decoration:none;font-weight:600;" target="_blank">{{ $en ? 'How to play' : 'طريقة اللعب' }}</a>
          &nbsp;·&nbsp; <a href="{{ $site }}/privacy{{ $en ? '?lang=en' : '' }}" style="color:#475467;text-decoration:none;font-weight:600;" target="_blank">{{ $en ? 'Privacy' : 'الخصوصية' }}</a>
          &nbsp;·&nbsp; <a href="mailto:game.legend.manager@gmail.com" style="color:#475467;text-decoration:none;font-weight:600;">{{ $en ? 'Support' : 'الدعم' }}</a>
        </div>
        <div class="glm-muted" style="font-size:12px;line-height:20px;color:#98A2B3;padding-top:14px;">
          @hasSection('footer')@yield('footer')<br>@endif
          {{ $en ? 'Game Legend Manager is an independent game, not affiliated with any club, league or football association.' : 'Game Legend Manager لعبة مستقلة، غير تابعة لأي نادٍ أو دوري أو اتحاد كرة قدم.' }}<br>
          © 2026 Game Legend Manager · <a href="{{ $site }}" style="color:#98A2B3;" target="_blank" dir="ltr">{{ $host }}</a>
        </div>
      </td></tr>
    </table>
  </td></tr>
</table>
</body>
</html>
