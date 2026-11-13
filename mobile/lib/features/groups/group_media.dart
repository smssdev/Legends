import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme.dart';

/// A picture sent in a group: private to its members, so fetched with the account's token, once.
class GroupImage extends ConsumerStatefulWidget {
  const GroupImage({super.key, required this.path});

  final String path;

  @override
  ConsumerState<GroupImage> createState() => _GroupImageState();
}

class _GroupImageState extends ConsumerState<GroupImage> {
  late final Future<List<int>> _bytes = ref.read(apiProvider).bytes(widget.path);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _bytes,
    builder: (_, s) => s.hasData && s.data!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(Uint8List.fromList(s.data!), width: 240, fit: BoxFit.cover),
          )
        : const SizedBox(width: 240, height: 140, child: Center(child: CircularProgressIndicator())),
  );
}

/// A voice note sent in a group: fetched once with the account's token, then played from the phone.
class GroupVoice extends ConsumerStatefulWidget {
  const GroupVoice({super.key, required this.path, required this.seconds});

  final String path;
  final int seconds;

  @override
  ConsumerState<GroupVoice> createState() => _GroupVoiceState();
}

class _GroupVoiceState extends ConsumerState<GroupVoice> {
  final _player = AudioPlayer();
  bool _playing = false, _loading = false;
  String? _file;
  StreamSubscription<void>? _done;

  @override
  void initState() {
    super.initState();
    _done = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    unawaited(_done?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    if (_file == null) {
      setState(() => _loading = true);
      try {
        final bytes = await ref.read(apiProvider).bytes(widget.path);
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/voice-${widget.path.hashCode}.m4a');
        await f.writeAsBytes(bytes);
        _file = f.path;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }
    await _player.play(DeviceFileSource(_file!));
    if (mounted) {
      setState(() {
        _playing = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: L.of(context).voiceNote(widget.seconds),
        onPressed: _loading ? null : _toggle,
        icon: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: context.palette.gold),
      ),
      Text(L.of(context).voiceNote(widget.seconds)),
    ],
  );
}
