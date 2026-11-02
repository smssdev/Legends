{{-- [X80] The email's one gold button, drawn with a table so every mail app shows it (full width on a phone). --}}
@php($font = "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Tahoma,Arial,sans-serif")
<tr><td align="center" class="glm-pad" style="padding:{{ $pad ?? '8px 40px 32px' }};">
  <table role="presentation" cellpadding="0" cellspacing="0" class="glm-btn" style="margin:0 auto;">
    <tr><td align="center" bgcolor="#F5B82E" style="border-radius:12px;background:#F5B82E;background-image:linear-gradient(180deg,#FFD36B,#F5B82E);">
      <a href="{{ $href }}" target="_blank" style="display:inline-block;padding:15px 36px;font-family:{{ $font }};font-size:16px;font-weight:700;line-height:20px;color:#0A1F42;text-decoration:none;border-radius:12px;">{{ $label }}</a>
    </td></tr>
  </table>
</td></tr>
