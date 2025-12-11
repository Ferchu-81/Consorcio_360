import 'package:consorcio_360/core/services/context_storage.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import 'package:consorcio_360/features/context/presentation/context_selection_screen.dart';
import 'package:consorcio_360/features/reclamos/presentation/main_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    _decidirInicio();
  }

  Future<void> _decidirInicio() async {
    final UsuarioContexto? ctx = await ContextStorage.cargarContexto();

    if (!mounted) return;

    if (ctx != null) {
      context.read<CurrentContextNotifier>().setContext(ctx);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainHomeScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ContextSelectionScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
