import 'package:consorcio_360/bases_legales/ui/bases_legales_screen.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/root/presentation/root_screen.dart';

class Consorcio360App extends StatelessWidget {
  const Consorcio360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consorcio 360',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
      ),
      routes: {
        '/bases-legales': (context) {
          final contexto = context.read<CurrentContextNotifier>().current;
          if (contexto == null) {
            return const Scaffold(
              body: Center(
                child: Text('No hay contexto seleccionado.'),
              ),
            );
          }
          return BasesLegalesScreen(consorcioId: contexto.consorcioId);
        },
      },
      home: const AuthGate(),
    );
  }
}

/// Decide si mostrar login o selector de contexto
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    } else {
      return const RootScreen();
    }
  }
}
