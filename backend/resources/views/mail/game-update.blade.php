{{--
  [X80] A game event by email: a match's result, with the score board as its hero (the two clubs, the score, the
  competition), the scorers and the way to the report; or any alert (a sale, an offer, a match about to start).
  $kind is the small label; $score, when there is one, is [home, home_goals, away_goals, away]; $facts are
  [label, value] rows (the scorers, the money, the time).
--}}
@extends('mail.layout')
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
@php($align = $en ? 'left' : 'right')
@php($end = $en ? 'right' : 'left')
@section('title'){{ $title }}@endsection
@section('preheader'){{ ! empty($score) ? "{$score[0]} {$score[1]} – {$score[2]} {$score[3]}. " : '' }}{{ $lead }}@endsection
@section('hero')
  @if(! empty($score))
  {{-- The score board: the clubs either side, the score large in gold, on the night of the stadium. --}}
  <tr><td bgcolor="#0B1A2C" class="glm-pad" style="background:#0B1A2C;background-image:radial-gradient(ellipse at top,#1D3A57 0%,#0B1A2C 60%,#06111E 100%);padding:34px 28px 30px;font-family:{{ $font }};" align="center">
    <div style="display:inline-block;font-size:12px;line-height:16px;font-weight:700;color:#0A1F42;background:#F5B82E;border-radius:999px;padding:5px 14px;">{{ $kind }}</div>
    {{-- The home side first in the reading direction (on the right in Arabic, as on the game's own match screen), its goals beside it. --}}
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" dir="{{ $en ? 'ltr' : 'rtl' }}" style="margin-top:22px;">
      <tr>
        <td width="38%" align="{{ $en ? 'right' : 'left' }}" valign="middle" style="font-size:17px;line-height:24px;font-weight:700;color:#FFFFFF;padding:0 8px;">{{ $score[0] }}</td>
        <td width="24%" align="center" valign="middle" class="glm-score" dir="ltr" style="font-family:'Arial Narrow','Helvetica Neue',Arial,sans-serif;font-size:54px;line-height:60px;font-weight:800;color:#F5B82E;white-space:nowrap;">{{ $en ? $score[1] : $score[2] }} – {{ $en ? $score[2] : $score[1] }}</td>
        <td width="38%" align="{{ $en ? 'left' : 'right' }}" valign="middle" style="font-size:17px;line-height:24px;font-weight:700;color:#FFFFFF;padding:0 8px;">{{ $score[3] }}</td>
      </tr>
    </table>
    <div style="font-size:13px;line-height:20px;color:#AEB9CC;padding-top:16px;">{{ $title }}</div>
  </td></tr>
  <tr><td class="glm-body glm-pad" style="background:#FFFFFF;padding:30px 40px 4px;text-align:{{ $align }};font-family:{{ $font }};">
    <p class="glm-text" style="margin:0;font-size:16px;line-height:26px;color:#475467;">{{ $lead }}</p>
  </td></tr>
  @else
    @include('mail.partials-hero', ['en' => $en, 'eyebrow' => $kind, 'title' => $title, 'lead' => $lead])
  @endif
@endsection
@section('body')
      @if(! empty($facts))
      <tr><td class="glm-pad" style="padding:22px 40px 6px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="glm-panel" style="border-collapse:separate;background:#F9FAFB;border:1px solid #EAECF0;border-radius:14px;" dir="{{ $en ? 'ltr' : 'rtl' }}">
          @foreach($facts as $i => [$label, $value])
          <tr>
            <td style="padding:13px 18px;{{ $i ? 'border-top:1px solid #EAECF0;' : '' }}font-family:{{ $font }};font-size:14px;line-height:20px;color:#667085;text-align:{{ $align }};" class="glm-muted glm-rule">{{ $label }}</td>
            <td style="padding:13px 18px;{{ $i ? 'border-top:1px solid #EAECF0;' : '' }}font-family:{{ $font }};font-size:15px;line-height:20px;font-weight:700;color:#0A1F42;text-align:{{ $end }};" class="glm-title glm-rule" dir="auto">{{ $value }}</td>
          </tr>
          @endforeach
        </table>
      </td></tr>
      @endif
      @include('mail.partials-button', ['href' => $url, 'label' => $button, 'pad' => '24px 40px 36px'])
@endsection
@section('footer'){{ $why }}@endsection
