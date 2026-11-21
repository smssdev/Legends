import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';

// يكتب gen-l10n أيضاً قائمة جاهزة، AppLocalizations.localizationsDelegates، لكنها ما زالت تسمّي
// نصوص Material كما كانت قبل Flutter 3.47. وإلى أن تُحدَّث، نسمّي المندوبين بأنفسنا.
const delegates = <LocalizationsDelegate<Object?>>[
  // نصوصنا، من ملفات ARB.
  AppLocalizations.delegate,
  // نصوص Material (حسنًا، وإلغاء، ومنتقي التاريخ)، ونصوص Cupertino، واتجاه النص.
  ...GlobalMaterialLocalizations.delegates,
];
