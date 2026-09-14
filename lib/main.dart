import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stacked_services/stacked_services.dart';

import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Obligatoire avant tout appel aux plugins natifs (secure storage plus tard)
  WidgetsFlutterBinding.ensureInitialized();

  // Enregistre tous les services déclarés dans app.dart (injection de dépendances)
  setupLocator();

  runApp(const StudUpApp());
}

class StudUpApp extends StatelessWidget {
  const StudUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // App en français : le sélecteur de dates s'affiche en français et la
      // semaine commence le lundi (convention de la locale fr) — APP-122.
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Clé de navigation partagée avec le NavigationService de Stacked :
      // permet de naviguer depuis les ViewModels sans BuildContext
      navigatorKey: StackedService.navigatorKey,
      onGenerateRoute: StackedRouter().onGenerateRoute,
    );
  }
}
