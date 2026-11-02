{{--
  [Sprint 38 M3] The store's deals and top-up offers, ready for when the store opens (README section 11): a banner line,
  up to four packs (name, what it gives, its price, and its old price struck through when it is a discount), until when
  the offer lasts, the button, and how to stop these emails. Nothing sends it yet: App\Notifications\StoreDealNotice.
--}}
@extends('mail.layout')
@php($align = $en ? 'left' : 'right')
@section('title'){{ $title }}@endsection
@section('preheader'){{ $lead }}@endsection
@section('body')
      <tr><td style="padding:0;background:#F5B82E;background-image:linear-gradient(135deg,#FFD36B,#F5B82E 55%,#C08A0C);text-align:center;">
        <p style="margin:0;padding:22px 32px 6px;font-size:24px;font-weight:800;color:#0A1F42;">{{ $title }}</p>
        <p style="margin:0;padding:0 32px 22px;font-size:15px;line-height:1.7;color:#0A1F42;">{{ $lead }}</p>
      </td></tr>
      <tr><td style="padding:20px 24px 4px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" dir="{{ $en ? 'ltr' : 'rtl' }}">
          @foreach(array_chunk($packs, 2) as $row)
          <tr>
            @foreach($row as $pack)
            <td width="50%" valign="top" style="padding:6px;">
              <div style="border:1px solid #E3E7EE;border-radius:12px;padding:14px;text-align:center;">
                @if(! empty($pack['badge']))<span style="display:inline-block;background:#0A1F42;color:#F5B82E;border-radius:999px;padding:2px 10px;font-size:11px;font-weight:700;">{{ $pack['badge'] }}</span>@endif
                <p style="margin:8px 0 4px;font-size:16px;font-weight:800;color:#0A1F42;">{{ $pack['name'] }}</p>
                <p style="margin:0 0 8px;font-size:13px;color:#6B7A90;">{{ $pack['gives'] }}</p>
                <p style="margin:0;font-size:18px;font-weight:800;color:#0A1F42;" dir="ltr">{{ $pack['price'] }}@if(! empty($pack['was'])) <s style="font-size:13px;font-weight:400;color:#8A96A8;">{{ $pack['was'] }}</s>@endif</p>
              </div>
            </td>
            @endforeach
            @if(count($row) === 1)<td width="50%"></td>@endif
          </tr>
          @endforeach
        </table>
      </td></tr>
      @if(! empty($until))
      <tr><td style="padding:8px 32px 0;text-align:center;font-size:13px;color:#C0392B;font-weight:700;">{{ $en ? "Until {$until}" : "حتى {$until}" }}</td></tr>
      @endif
      @include('mail.partials-button', ['href' => $url, 'label' => $button])
@endsection
@section('footer'){{ $en ? 'Offers come only to coaches who asked for them. To stop them: My account, then Notifications.' : 'العروض تصل فقط لمن طلبها. لإيقافها: حسابي ثم الإشعارات.' }}@endsection
