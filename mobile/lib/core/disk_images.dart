import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

import 'hash.dart';

/// [Sprint 61 F6] The pictures from the network kept on the phone (the crests, the store's items, the announcements,
/// the avatars): fetched once, then read from the disk, by their address (a new version has a new `?v=`). At most
/// [maxBytes]; past it the least recently used go first.
class DiskImages {
  DiskImages({Future<Directory> Function()? dir, Future<Uint8List> Function(String url)? fetch})
    : _dir = dir ?? _defaultDir,
      _fetch = fetch ?? _httpFetch;

  /// For the widget tests, whose clock is not the disk's: every picture fails at once, as the network does there.
  DiskImages.none()
    : this(dir: () => Future.error(const FileSystemException('none')), fetch: (_) => Future.error(const HttpException('none')));

  static DiskImages instance = DiskImages();

  static const maxBytes = 50 * 1024 * 1024;

  final Future<Directory> Function() _dir;
  final Future<Uint8List> Function(String url) _fetch;
  Directory? _root;

  /// The pictures on their way or read this session, so a rebuild does not read them again (at most 200).
  final Map<String, Future<Uint8List>> _loading = {};

  static Future<Directory> _defaultDir() async => Directory('${(await getApplicationCacheDirectory()).path}/images');

  static Future<Uint8List> _httpFetch(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final r = await (await client.getUrl(Uri.parse(url))).close();
      if (r.statusCode != 200) throw HttpException('${r.statusCode}', uri: Uri.parse(url));
      return await consolidateHttpClientResponseBytes(r);
    } finally {
      client.close();
    }
  }

  Future<Uint8List> load(String url) {
    final known = _loading[url];
    if (known != null) return known;
    if (_loading.length >= 200) _loading.remove(_loading.keys.first);
    final f = _load(url);
    _loading[url] = f;
    // A failure is not kept: the next show asks again.
    f.catchError((Object _) {
      _loading.remove(url);
      return Uint8List(0);
    });
    return f;
  }

  Future<Uint8List> _load(String url) async {
    final root = _root ??= await _dir();
    final file = File('${root.path}/${fnv64(url)}');
    if (file.existsSync()) {
      // Used now: the last to go.
      unawaited(file.setLastModified(DateTime.now()).catchError((Object _) {}));
      return file.readAsBytes();
    }
    final bytes = await _fetch(url);
    try {
      await root.create(recursive: true);
      await file.writeAsBytes(bytes);
      unawaited(trim());
    } catch (_) {
      // A phone that cannot write still shows the picture.
    }
    return bytes;
  }

  /// Down to three quarters of [maxBytes] when past it, the least recently used first.
  Future<void> trim() async {
    final root = _root ??= await _dir();
    if (!root.existsSync()) return;
    final files = [
      for (final e in root.listSync())
        if (e is File) (e, e.statSync()),
    ];
    var total = files.fold<int>(0, (s, f) => s + f.$2.size);
    if (total <= maxBytes) return;
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (f, st) in files) {
      if (total <= maxBytes * 3 ~/ 4) break;
      try {
        f.deleteSync();
        total -= st.size;
      } catch (_) {}
    }
  }
}

/// A picture from [url] through [DiskImages]: as Image.network, kept on the phone.
@immutable
class DiskImage extends ImageProvider<DiskImage> {
  const DiskImage(this.url, {this.cacheWidth});

  final String url;

  /// [Sprint 74 P5] The widest the picture is ever shown, in real pixels: it is decoded no larger (a 1280 store picture
  /// in a 300 card held 1280×720×4 bytes in memory, four megabytes each). A smaller picture is left as it is.
  final int? cacheWidth;

  @override
  Future<DiskImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(DiskImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _codec(decode), scale: 1, debugLabel: url);

  /// The size to decode a [w]×[h] picture at for a slot [max] wide. Pure.
  static (int, int) fit(int w, int h, int max) => w <= max ? (w, h) : (max, (h * max / w).round().clamp(1, h));

  Future<ui.Codec> _codec(ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(await DiskImages.instance.load(url));
    final max = cacheWidth;
    if (max == null) return decode(buffer);
    return decode(
      buffer,
      getTargetSize: (w, h) {
        final (tw, th) = fit(w, h, max);
        return ui.TargetImageSize(width: tw, height: th);
      },
    );
  }

  @override
  bool operator ==(Object other) => other is DiskImage && other.url == url && other.cacheWidth == cacheWidth;

  @override
  int get hashCode => Object.hash(url, cacheWidth);
}
