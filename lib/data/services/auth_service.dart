import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticacion centralizado.
/// Por ahora lo usamos solo para Google; despues podemos mover
/// aca tambien el login/logout con email si queres.
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Login con Google usando google_sign_in + Supabase auth.
  Future<AuthResponse> signInWithGoogle() async {
    // ESTE clientId tiene que coincidir con el del JSON de Google
    const webClientId =
        '286790326022-v93cmqtl4jk9lkcith6lanqmejvipip5.apps.googleusercontent.com';

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: ['email', 'profile'],
    );

    // Abre el selector de cuentas de Google en Android
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // Usuario cancelo el login
      throw const AuthException(
        'Inicio de sesion con Google cancelado por el usuario',
      );
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw const AuthException('No se pudieron obtener los tokens de Google');
    }

    return _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
