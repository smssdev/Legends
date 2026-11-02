{{--
  [Sprint 39 M2] A game event by email: a match's result (the score board), or any alert (a sale, an offer, a match
  about to start). $kind is a small label over the title; $score, when there is one, is [home, home_goals, away_goals,
  away]; $facts are [label, value] rows (the scorers, the money, the time); then the button.
--}}
@extends('mail.layout')
@php($align = $en ? 'left' : 'right')
@section('title'){{ $title }}@endsection
@section('preheader'){{ $lead }}@endsection
@section('body')
      <tr><td style="padding:28px 32px 4px;text-align:{{ $align }};">
        <span style="display:inline-block;background:#F7F4EA;color:#9A6B00;border-radius:999px;padding:3px 12px;font-size:12px;font-weight:700;">{{ $kind }}</span>
        <h1 style="margin:10px 0 8px;font-size:22px;line-height:1.4;color:#0A1F42;">{{ $title }}</h1>
        <p style="margin:0;font-size:15px;line-height:1.8;color:#3B4A63;">{{ $lead }}</p>
      </td></tr>
      @if(! empty($score))
      <tr><td align="center" style="padding:20px 32px 8px;">
        <table role="presentation" cellpadding="0" cellspacing="0" style="background:#0A1F42;border-radius:14px;" dir="ltr">
          <tr>
            <td style="padding:16px 18px;color:#F7F4EA;font-size:15px;font-weight:700;text-align:right;min-width:120px;">{{ $score[0] }}</td>
            <td style="padding:16px 8px;color:#F5B82E;font-family:'Arial Narrow',Arial,sans-serif;font-size:34px;font-weight:800;white-space:nowrap;">{{ $score[1] }} – {{ $score[2] }}</td>
            <td style="padding:16px 18px;color:#F7F4EA;font-size:15px;font-weight:700;text-align:left;min-width:120px;">{{ $score[3] }}</td>
          </tr>
        </table>
      </td></tr>
      @endif
      @if(! empty($facts))
      <tr><td style="padding:12px 32px 8px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;" dir="{{ $en ? 'ltr' : 'rtl' }}">
          @foreach($facts as [$label, $value])
          <tr><td style="padding:8px 0;border-bottom:1px solid #EEF1F6;font-size:14px;color:#6B7A90;text-align:{{ $align }};">{{ $label }}</td>
              <td style="padding:8px 0;border-bottom:1px solid #EEF1F6;font-size:14px;font-weight:700;color:#0A1F42;text-align:{{ $en ? 'right' : 'left' }};">{{ $value }}</td></tr>
          @endforeach
        </table>
      </td></tr>
      @endif
      @include('mail.partials-button', ['href' => $url, 'label' => $button])
@endsection
@section('footer'){{ $en ? 'You get this because of your account in the game.' : 'وصلتك هذه الرسالة بسبب حسابك في اللعبة.' }}@endsection
