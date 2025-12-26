import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenService {
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await _requestPermission();
    await _registerToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _upsertToken(token);
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session?.user != null) {
        _registerToken();
      }
    });
  }

  static Future<void> _requestPermission() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
  }

  static String? _platformLabel() {
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

  static Future<void> _registerToken() async {
    if (kIsWeb) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;

    await _upsertToken(token, userId: user.id);
  }

  static Future<void> _upsertToken(
    String token, {
    String? userId,
  }) async {
    if (kIsWeb) return;
    final user = Supabase.instance.client.auth.currentUser;
    final resolvedUserId = userId ?? user?.id;
    if (resolvedUserId == null) return;

    final platform = _platformLabel();
    if (platform == null) return;

    await Supabase.instance.client.from('user_device_tokens').upsert(
      {
        'usuario_id': resolvedUserId,
        'token': token,
        'platform': platform,
        'last_seen_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'usuario_id,token',
    );
  }
}
