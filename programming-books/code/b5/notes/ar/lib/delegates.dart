import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

// As in Chapter 13.
const delegates = <LocalizationsDelegate<Object?>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
