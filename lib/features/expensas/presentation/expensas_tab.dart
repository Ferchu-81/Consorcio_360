import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_admin_tab.dart';
import 'package:consorcio_360/features/expensas/presentation/expensas_morador_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Wrapper que decide vista morador o admin segun el rol actual.
class ExpensasTab extends StatelessWidget {
  const ExpensasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final contexto = context.watch<CurrentContextNotifier>().current;

    if (contexto == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hay contexto seleccionado.'),
        ),
      );
    }

    final bool esAdmin = contexto.rol == 'ADMIN_CONSORCIO';

    if (esAdmin) {
      return ExpensasAdminTab(consorcioId: contexto.consorcioId);
    }

    return ExpensasMoradorTab(unidadId: contexto.unidadId);
  }
}
