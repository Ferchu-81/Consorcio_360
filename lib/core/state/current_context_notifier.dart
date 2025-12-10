import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:flutter/foundation.dart';

/// Estado global del contexto actual (consorcio + unidad + rol).
class CurrentContextNotifier extends ChangeNotifier {
  UsuarioContexto? _current;

  UsuarioContexto? get current => _current;
  bool get hasContext => _current != null;

  void setContext(UsuarioContexto contexto) {
    _current = contexto;
    notifyListeners();
  }

  void clear() {
    _current = null;
    notifyListeners();
  }
}