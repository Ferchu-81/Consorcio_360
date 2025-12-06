import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/context/presentation/context_selection_screen.dart';

class Consorcio360App extends StatelessWidget {
  const Consorcio360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consorcio 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
      ),
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
      return const ContextSelectionScreen();
    }
  }
}
