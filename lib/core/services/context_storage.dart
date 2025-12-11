import 'dart:convert';

import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContextStorage {
  static const _key = 'ultimo_contexto';

  static Future<void> guardarContexto(UsuarioContexto ctx) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(ctx.toJson());
    await prefs.setString(_key, jsonStr);
  }

  static Future<UsuarioContexto?> cargarContexto() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return null;
    return UsuarioContexto.fromJson(jsonDecode(jsonStr));
  }

  static Future<void> limpiarContexto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
