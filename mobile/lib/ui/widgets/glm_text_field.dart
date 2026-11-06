import 'package:flutter/material.dart';

import '../theme.dart';

/// [Sprint 15 F2] A labelled field as on the web: the label above, the server's message under it, emails, usernames
/// and passwords left to right (README «الواجهة»), and a password's eye.
class GlmTextField extends StatefulWidget {
  const GlmTextField({super.key, required this.label, required this.controller, this.hint, this.error, this.password = false, this.ltr = false,
      this.keyboard, this.autofill, this.action = TextInputAction.next, this.onSubmitted, this.validator});

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final bool password;
  final bool ltr;
  final TextInputType? keyboard;
  final Iterable<String>? autofill;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  @override
  State<GlmTextField> createState() => _GlmTextFieldState();
}

class _GlmTextFieldState extends State<GlmTextField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6), child: Text(widget.label, style: context.text.labelLarge?.copyWith(color: context.palette.textSoft, fontSize: 14))),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.password && _hidden,
          textDirection: widget.ltr || widget.password ? TextDirection.ltr : null,
          keyboardType: widget.keyboard,
          autofillHints: widget.autofill,
          textInputAction: widget.action,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          autocorrect: !widget.ltr && !widget.password,
          enableSuggestions: !widget.password,
          style: context.text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.error,
            errorMaxLines: 3,
            suffixIcon: widget.password
                ? IconButton(
                    tooltip: _hidden ? 'Show' : 'Hide',
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.palette.textMuted),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
