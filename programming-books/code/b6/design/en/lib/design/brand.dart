import 'package:material_ui/material_ui.dart';

// The brand's own colours, next to Material's: a ThemeExtension travels with the theme.
@immutable
class Brand extends ThemeExtension<Brand> {
  const Brand({
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.muted,
  });

  // Every colour comes with the colour of what is written on it.
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color muted;

  static const light = Brand(
    accent: Color(0xFF6D4C41),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF1B5E20),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFFFB300),
    onWarning: Color(0xFF3E2723),
    muted: Color(0xFFF3EDE7),
  );

  static const dark = Brand(
    accent: Color(0xFFD7B8A8),
    onAccent: Color(0xFF3E2723),
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF0B3D0E),
    warning: Color(0xFFFFCA28),
    onWarning: Color(0xFF3E2723),
    muted: Color(0xFF2B2420),
  );

  @override
  Brand copyWith({Color? accent, Color? onAccent}) => Brand(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success,
    onSuccess: onSuccess,
    warning: warning,
    onWarning: onWarning,
    muted: muted,
  );

  // lerp: how a colour moves between two themes, so that switching animates instead of jumping.
  @override
  Brand lerp(Brand? other, double t) {
    if (other == null) {
      return this;
    }
    return Brand(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
    );
  }
}
