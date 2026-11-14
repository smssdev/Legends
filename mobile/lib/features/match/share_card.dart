import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/tokens.g.dart';
import '../../ui/widgets/glm_button.dart';
import '../../ui/widgets/glm_icon.dart';

/// [Sprint 64 F8] The result to share, as the site's share card (lib/shareCard.ts): the report's score card itself (the
/// score, the result, the man of the match) taken as one picture, with a line of text, to WhatsApp or anywhere the
/// phone's share sheet offers.
class ShareableResult extends StatefulWidget {
  const ShareableResult({super.key, required this.child, required this.text});

  final Widget child;
  final String text;

  @override
  State<ShareableResult> createState() => _ShareableResultState();
}

class _ShareableResultState extends State<ShareableResult> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final box = _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final image = await box?.toImage(pixelRatio: 2);
      final png = await image?.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(
        ShareParams(
          text: widget.text,
          files: png == null ? null : [XFile.fromData(png.buffer.asUint8List(), mimeType: 'image/png', name: 'glm-result.png')],
        ),
      );
    } catch (_) {
      // Nothing shared: the coach can try again.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RepaintBoundary(key: _card, child: widget.child),
      const SizedBox(height: GlmSpace.sm),
      Align(
        child: GlmButton(
          label: L.of(context).shareResult,
          icon: const GlmIcon(GlmIcons.share),
          variant: GlmButtonVariant.outline,
          loading: _busy,
          onPressed: _share,
        ),
      ),
    ],
  );
}
