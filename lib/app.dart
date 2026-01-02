import 'package:consorcio_360/features/root/presentation/root_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:consorcio_360/gen_l10n/app_localizations.dart';

class Consorcio360App extends StatelessWidget {
  const Consorcio360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consorcio 360',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RootScreen(),
    );
  }
}
