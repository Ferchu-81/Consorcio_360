import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/state/current_context_notifier.dart';
import 'data/services/push_token_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  try {
    await Firebase.initializeApp();
    await PushTokenService.start();
  } catch (_) {}

  runApp(
    ChangeNotifierProvider(
      create: (_) => CurrentContextNotifier(),
      child: const Consorcio360App(),
    ),
  );
}
