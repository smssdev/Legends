{{-- The verification code email [Sprint 21 E2.4], in the game's frame [X80]. --}}
@extends('mail.layout')
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
@php($align = $en ? 'left' : 'right')
@section('title'){{ $en ? 'Your verification code' : 'كود توثيق حسابك' }}@endsection
@section('preheader'){{ $en ? "Your code is {$code}. It is valid for {$minutes} minutes." : "كودك {$code}، صالح {$minutes} دقيقة." }}@endsection
@section('hero')
  @include('mail.partials-hero', ['en' => $en, 'eyebrow' => $en ? 'Account security' : 'أمان الحساب', 'title' => $en ? 'Verify your account' : 'وثّق حسابك',
    'lead' => $en ? "Hello {$name}, here is the code to verify your account." : "أهلاً {$name}، هذا كود توثيق حسابك."])
@endsection
@section('body')
      <tr><td class="glm-pad" style="padding:8px 40px 0;text-align:{{ $align }};font-family:{{ $font }};">
        <p class="glm-muted" style="margin:0;font-size:14px;line-height:22px;color:#667085;">
          <span dir="ltr" style="color:#0A1F42;font-weight:700;">&#64;{{ $username }}</span>@if($accountNo) &nbsp;·&nbsp; {{ $en ? 'Account' : 'رقم الحساب' }} <span dir="ltr">{{ $accountNo }}</span>@endif
        </p>
      </td></tr>
      <tr><td align="center" class="glm-pad" style="padding:28px 40px 8px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="glm-panel" style="border-collapse:separate;background:#F7F4EA;border:1px solid #F0DDA8;border-radius:16px;">
          <tr><td align="center" style="padding:26px 16px 22px;font-family:{{ $font }};">
            <div class="glm-muted" style="font-size:12px;line-height:16px;font-weight:700;color:#8A6A12;padding-bottom:10px;">{{ $en ? 'YOUR CODE' : 'كودك' }}</div>
            <div dir="ltr" style="font-family:'SF Mono',Menlo,Consolas,'Courier New',monospace;font-size:40px;line-height:48px;font-weight:700;letter-spacing:10px;color:#0A1F42;">{{ $code }}</div>
            <div class="glm-muted" style="font-size:13px;line-height:20px;color:#667085;padding-top:10px;">{{ $en ? "Valid for {$minutes} minutes, and only once." : "صالح {$minutes} دقيقة، ولمرة واحدة فقط." }}</div>
          </td></tr>
        </table>
      </td></tr>
      @include('mail.partials-button', ['href' => $url, 'label' => $en ? 'Open my account' : 'افتح حسابي', 'pad' => '28px 40px 8px'])
      <tr><td class="glm-pad" style="padding:20px 40px 36px;text-align:{{ $align }};font-family:{{ $font }};">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td class="glm-rule glm-muted" style="border-top:1px solid #EAECF0;padding-top:18px;font-size:13px;line-height:21px;color:#667085;">
          <b style="color:#344054;">{{ $en ? 'Keep it to yourself.' : 'لا تشاركه مع أحد.' }}</b> {{ $en ? 'The game\'s team will never ask you for this code.' : 'فريق اللعبة لن يطلب منك هذا الكود أبداً.' }}<br>
          {{ $en ? 'Did not ask for it? Ignore this email: your account stays as it is.' : 'لم تطلبه؟ تجاهل هذه الرسالة، وحسابك يبقى كما هو.' }}
        </td></tr></table>
      </td></tr>
@endsection
@section('footer'){{ $en ? 'You received this because a verification code was asked for your account.' : 'وصلتك هذه الرسالة لأن كود توثيق طُلب لحسابك.' }}@endsection
