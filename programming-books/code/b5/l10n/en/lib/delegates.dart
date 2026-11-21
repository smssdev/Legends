import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

// gen-l10n also writes a ready list, AppLocalizations.localizationsDelegates, but it still names
// Material's texts as they were before Flutter 3.47. Until it is updated, we name the delegates ourselves.
const delegates = <LocalizationsDelegate<Object?>>[
  // Our texts, from the ARB files.
  AppLocalizations.delegate,
  // Material's texts (OK, Cancel, the date picker), Cupertino's, and the direction of the text.
  ...GlobalMaterialLocalizations.delegates,
];
