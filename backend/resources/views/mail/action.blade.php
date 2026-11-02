{{--
  [Sprint 38 M1] An email with one thing to do (confirm the email, choose a new password): a title, its lines, the button,
  and a closing line. $lines and $after are plain text, escaped here.
--}}
@extends('mail.layout')
@php($align = $en ? 'left' : 'right')
@section('title'){{ $title }}@endsection
@section('preheader'){{ $lines[0] ?? $title }}@endsection
@section('body')
      <tr><td style="padding:32px 32px 8px;text-align:{{ $align }};">
        <h1 style="margin:0 0 12px;font-size:22px;line-height:1.4;color:#0A1F42;">{{ $title }}</h1>
        <p style="margin:0 0 8px;font-size:15px;line-height:1.8;color:#3B4A63;">{{ $greeting }}</p>
        @foreach($lines as $line)<p style="margin:0 0 8px;font-size:15px;line-height:1.8;color:#3B4A63;">{{ $line }}</p>@endforeach
      </td></tr>
      @include('mail.partials-button', ['href' => $url, 'label' => $button])
      <tr><td style="padding:0 32px 28px;text-align:{{ $align }};">
        <div style="border-top:1px solid #E3E7EE;padding-top:16px;font-size:13px;line-height:1.8;color:#6B7A90;">{{ $after }}</div>
        <p style="margin:12px 0 0;font-size:12px;line-height:1.7;color:#8A96A8;word-break:break-all;" dir="ltr">{{ $url }}</p>
      </td></tr>
@endsection
