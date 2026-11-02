{{--
  [X80] An email with one thing to do (confirm the email, choose a new password): the hero, its lines, the button, the
  link in full for a mail app that hides buttons, and a closing line. $lines and $after are plain text, escaped here.
--}}
@extends('mail.layout')
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
@php($align = $en ? 'left' : 'right')
@section('title'){{ $title }}@endsection
@section('preheader'){{ $lines[0] ?? $title }}@endsection
@section('hero')
  @include('mail.partials-hero', ['en' => $en, 'eyebrow' => $eyebrow ?? ($en ? 'Your account' : 'حسابك'), 'title' => $title, 'lead' => $greeting])
@endsection
@section('body')
      <tr><td class="glm-pad" style="padding:6px 40px 8px;text-align:{{ $align }};font-family:{{ $font }};">
        @foreach($lines as $line)<p class="glm-text" style="margin:0 0 12px;font-size:16px;line-height:26px;color:#475467;">{{ $line }}</p>@endforeach
      </td></tr>
      @include('mail.partials-button', ['href' => $url, 'label' => $button, 'pad' => '12px 40px 8px'])
      <tr><td class="glm-pad" style="padding:20px 40px 36px;text-align:{{ $align }};font-family:{{ $font }};">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td class="glm-rule glm-muted" style="border-top:1px solid #EAECF0;padding-top:18px;font-size:13px;line-height:21px;color:#667085;">
          {{ $after }}
          <div style="padding-top:12px;">{{ $en ? 'Button not working? Copy this link into your browser:' : 'الزر لا يعمل؟ انسخ هذا الرابط في متصفحك:' }}</div>
          <div dir="ltr" style="padding-top:4px;font-size:12px;line-height:18px;word-break:break-all;"><a href="{{ $url }}" style="color:#B7860B;" target="_blank">{{ $url }}</a></div>
        </td></tr></table>
      </td></tr>
@endsection
@section('footer'){{ $en ? 'You received this because of a request on your account.' : 'وصلتك هذه الرسالة بسبب طلب على حسابك.' }}@endsection
