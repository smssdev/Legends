{{-- [X80] The email's hero: a small label in gold, the one message in large type, and a line under it. --}}
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
<tr><td class="glm-body glm-pad" style="background:#FFFFFF;padding:40px 40px 8px;text-align:{{ $en ? 'left' : 'right' }};font-family:{{ $font }};">
  @if(! empty($eyebrow))<div style="font-size:12px;line-height:16px;font-weight:700;letter-spacing:{{ $en ? '1.5px' : '0' }};text-transform:uppercase;color:#B7860B;padding-bottom:10px;">{{ $eyebrow }}</div>@endif
  <h1 class="glm-title glm-hero-title" style="margin:0;font-size:30px;line-height:38px;font-weight:800;color:#0A1F42;">{{ $title }}</h1>
  @if(! empty($lead))<p class="glm-text" style="margin:14px 0 0;font-size:16px;line-height:26px;color:#475467;">{{ $lead }}</p>@endif
</td></tr>
