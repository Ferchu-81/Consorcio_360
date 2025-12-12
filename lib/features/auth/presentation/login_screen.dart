import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../context/presentation/context_selection_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res.session != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ContextSelectionScreen()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Error inesperado. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa un email válido en el campo Email para recuperar la contraseña.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.resetPasswordForEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el email existe, enviamos un enlace para restablecer la contraseña.',
          ),
        ),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'No se pudo iniciar el proceso de recuperación. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToSignup() {
    if (_isLoading) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/icon/consorcio_360_icon.png',
                    height: 120,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Consorcio 360',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                        ],
                        FilledButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Ingresar'),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _goToSignup,
                          child: const Text('¿No tenés cuenta? Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
