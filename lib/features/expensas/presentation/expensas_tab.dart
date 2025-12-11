import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/data/models/usuario_contexto.dart';
import './expensas_admin_tab.dart';
import './expensas_morador_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrapper que decide vista morador o admin segun el rol actual.
class ExpensasTab extends StatelessWidget {
  final UsuarioContexto? contexto;

  const ExpensasTab({super.key, this.contexto});

  @override
  Widget build(BuildContext context) {
    final ctx = contexto ?? context.watch<CurrentContextNotifier>().current;

    if (ctx == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay contexto seleccionado.'),
        ),
      );
    }

    final bool esAdmin = ctx.rol == 'ADMIN_CONSORCIO';

    if (esAdmin) {
      return ExpensasAdminTab(
        consorcioId: ctx.consorcioId,
        consorcioNombre: ctx.consorcioNombre,
      );
    }

    return ExpensasMoradorTab(unidadId: ctx.unidadId);
  }
}
