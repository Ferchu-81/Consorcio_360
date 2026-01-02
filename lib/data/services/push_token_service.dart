import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenService {
  PushTokenService._();

  static final instance = PushTokenService._();

  bool _initialized = false;

  static Future<void> start({String? consorcioId}) async {
    await instance.ensureInitializedAndSync(consorcioId: consorcioId);
  }

  Future<void> ensureInitializedAndSync({String? consorcioId}) async {
    if (_initialized) {
      await _sync(consorcioId: consorcioId);
      return;
    }

    _initialized = true;

    await _requestPermission();
    await _sync(consorcioId: consorcioId);

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _upsertToken(token, consorcioId: consorcioId);
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      final session = event.session;
      if (session?.user != null) {
        await _sync(consorcioId: consorcioId);
      }
    });
  }

  Future<void> _sync({String? consorcioId}) async {
    if (kIsWeb) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _upsertToken(token, consorcioId: consorcioId);
  }

  Future<void> _upsertToken(String token, {String? consorcioId}) async {
    if (kIsWeb) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = _platformLabel();
    if (platform == null) return;

    final data = <String, dynamic>{
      'usuario_id': userId,
      'token': token,
      'platform': platform,
      'last_seen_at': DateTime.now().toIso8601String(),
      if (consorcioId != null && consorcioId.trim().isNotEmpty)
        'consorcio_id': consorcioId,
    };

    await Supabase.instance.client
        .from('user_device_tokens')
        .upsert(data, onConflict: 'usuario_id,token');
  }

  String? _platformLabel() {
    if (kIsWeb) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return null;
    }
  }

  Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
  }
}
