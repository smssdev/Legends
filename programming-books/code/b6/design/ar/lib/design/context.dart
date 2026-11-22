import 'package:material_ui/material_ui.dart';

import 'brand.dart';

// أسماء قصيرة للشاشات: context.brand وcontext.colors وcontext.text.
extension DesignContext on BuildContext {
  Brand get brand => Theme.of(this).extension<Brand>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
