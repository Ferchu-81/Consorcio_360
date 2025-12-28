import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushTokenService {
  PushTokenService._();
  static final PushTokenService instance = PushTokenService._();

  bool _initialized = false;

  String _platformLabel() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<void> ensureInitializedAndSync() async {
    if (!_initialized) {
      _initialized = true;

      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        debugPrint('PushTokenService: requestPermission error: $e');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await _upsertToken(token);
      });
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('PushTokenService: token is null/empty');
      return;
    }
    await _upsertToken(token);
  }

  Future<void> _upsertToken(String token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint('PushTokenService: no auth user');
      return;
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();

    final payload = <String, dynamic>{
      'usuario_id': userId,
      'platform': _platformLabel(),
      'token': token,
      'last_seen_at': nowIso,
    };

    try {
      await supabase.from('user_device_tokens').upsert(
        payload,
        onConflict: 'usuario_id,token',
      );

      debugPrint(
        'PushTokenService: token upsert OK (platform=${payload['platform']})',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        'PushTokenService: Postgrest error: ${e.message} code=${e.code} '
        'details=${e.details} hint=${e.hint}',
      );
      rethrow;
    } catch (e) {
      debugPrint('PushTokenService: unexpected error: $e');
      rethrow;
    }
  }
}
