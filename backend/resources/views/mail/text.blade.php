{{-- [X80] The plain text twin of every email (mail apps that show no HTML, and a better way into the inbox). --}}
{!! $heading !!}

@foreach($textLines ?? $lines as $line)
{!! $line !!}
@endforeach

{!! $button !!}: {!! $url !!}

--
Game Legend Manager{{ $en ? '' : ' · المدرب الأسطورة' }}
{!! rtrim((string) config('app.url'), '/') !!}
