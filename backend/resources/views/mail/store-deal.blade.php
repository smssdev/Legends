{{--
  [X80] The store's deals and top-up offers, ready for when the store opens (README section 11): a gold banner, up to
  four packs (name, what it gives, its price, its old price struck through on a discount, a badge), until when the
  offer lasts, the button, and how to stop these emails. Nothing sends it yet: App\Notifications\StoreDealNotice.
--}}
@extends('mail.layout')
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
@section('title'){{ $title }}@endsection
@section('preheader'){{ $lead }}@endsection
@section('hero')
  <tr><td align="center" bgcolor="#F5B82E" class="glm-pad" style="background:#F5B82E;background-image:linear-gradient(135deg,#FFE29A 0%,#F5B82E 50%,#C08A0C 100%);padding:38px 40px 34px;font-family:{{ $font }};">
    <div style="display:inline-block;font-size:12px;line-height:16px;font-weight:700;color:#F5B82E;background:#0A1F42;border-radius:999px;padding:5px 14px;">{{ $en ? 'Store offer' : 'عرض المتجر' }}</div>
    <h1 class="glm-hero-title" style="margin:16px 0 0;font-size:32px;line-height:40px;font-weight:800;color:#0A1F42;">{{ $title }}</h1>
    <p style="margin:10px 0 0;font-size:16px;line-height:24px;color:#3D3000;">{{ $lead }}</p>
  </td></tr>
@endsection
@section('body')
      @if(! empty($image))
      <tr><td class="glm-pad" style="padding:24px 28px 0;"><img src="{{ $image }}" width="544" alt="{{ $title }}" style="display:block;width:100%;max-width:544px;height:auto;border-radius:16px;border:0;"></td></tr>
      @endif
      <tr><td class="glm-pad" style="padding:26px 28px 4px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" dir="{{ $en ? 'ltr' : 'rtl' }}">
          @foreach(array_chunk($packs, 2) as $row)
          <tr>
            @foreach($row as $pack)
            <td width="50%" valign="top" style="padding:6px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" class="glm-panel" style="border-collapse:separate;border:1px solid #EAECF0;border-radius:16px;background:#FFFFFF;">
                <tr><td align="center" style="padding:20px 14px;font-family:{{ $font }};">
                  @if(! empty($pack['badge']))<div dir="ltr" style="display:inline-block;background:#0A1F42;color:#F5B82E;border-radius:999px;padding:3px 12px;font-size:12px;line-height:16px;font-weight:700;">{{ $pack['badge'] }}</div>@endif
                  <div class="glm-title" style="font-size:19px;line-height:26px;font-weight:800;color:#0A1F42;padding-top:10px;">{{ $pack['name'] }}</div>
                  <div class="glm-muted" style="font-size:13px;line-height:20px;color:#667085;padding-top:2px;">{{ $pack['gives'] }}</div>
                  <div dir="ltr" class="glm-title" style="font-size:24px;line-height:30px;font-weight:800;color:#0A1F42;padding-top:12px;">{{ $pack['price'] }}@if(! empty($pack['was'])) <s style="font-size:14px;font-weight:400;color:#98A2B3;">{{ $pack['was'] }}</s>@endif</div>
                </td></tr>
              </table>
            </td>
            @endforeach
            @if(count($row) === 1)<td width="50%"></td>@endif
          </tr>
          @endforeach
        </table>
      </td></tr>
      @if(! empty($until))
      <tr><td align="center" style="padding:14px 40px 0;font-family:{{ $font }};font-size:14px;line-height:20px;font-weight:700;color:#C4320A;">{{ $en ? "Until {$until}" : "حتى {$until}" }}</td></tr>
      @endif
      @include('mail.partials-button', ['href' => $url, 'label' => $button, 'pad' => '20px 40px 36px'])
@endsection
@section('footer'){{ $en ? 'Offers come only to coaches who asked for them. To stop them: My account, then Notifications.' : 'العروض تصل فقط لمن طلبها. لإيقافها: حسابي ثم الإشعارات.' }}@endsection
