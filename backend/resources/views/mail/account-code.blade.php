{{-- The verification code email [Sprint 21 E2.4], in the shared frame [Sprint 38 M1]. --}}
@extends('mail.layout')
@php($align = $en ? 'left' : 'right')
@section('title'){{ $en ? 'Your verification code' : 'كود توثيق حسابك' }}@endsection
@section('preheader'){{ $en ? "Your code: {$code}. Valid for {$minutes} minutes." : "كودك: {$code}. صالح {$minutes} دقيقة." }}@endsection
@section('body')
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
      @include('mail.partials-button', ['href' => $url, 'label' => $en ? 'Open my account' : 'افتح حسابي'])
      <tr><td style="padding:0 32px 28px;text-align:{{ $align }};">
        <div style="border-top:1px solid #E3E7EE;padding-top:16px;font-size:13px;line-height:1.8;color:#6B7A90;">
          {{ $en ? 'Never share this code with anyone. The game\'s team will never ask you for it.' : 'لا تشارك هذا الكود مع أحد. فريق اللعبة لن يطلبه منك أبداً.' }}<br>
          {{ $en ? 'If you did not ask for it, ignore this email: your account stays as it is.' : 'إن لم تطلبه فتجاهل هذه الرسالة، وحسابك يبقى كما هو.' }}
        </div>
      </td></tr>
@endsection
