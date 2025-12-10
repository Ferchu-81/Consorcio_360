import 'package:consorcio_360/data/repositories/expensas_repository.dart';
import 'package:flutter/material.dart';

/// Pantalla simple para crear una expensa manual (solo admin).
class NuevaExpensaScreen extends StatefulWidget {
  final String consorcioId;

  const NuevaExpensaScreen({super.key, required this.consorcioId});

  @override
  State<NuevaExpensaScreen> createState() => _NuevaExpensaScreenState();
}

class _NuevaExpensaScreenState extends State<NuevaExpensaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importeController = TextEditingController();
  final ExpensasRepository _repo = ExpensasRepository();

  String? _unidadSeleccionada;
  List<Map<String, dynamic>> _unidades = [];
  DateTime _periodo = DateTime.now();
  DateTime _fechaVenc = DateTime.now().add(const Duration(days: 15));
  bool _guardando = false;
  bool _cargandoUnidades = true;

  @override
  void initState() {
    super.initState();
    _loadUnidades();
  }

  Future<void> _loadUnidades() async {
    try {
      final data = await _repo.fetchUnidadesDeConsorcio(widget.consorcioId);
      if (!mounted) return;
      setState(() {
        _unidades = data;
        _cargandoUnidades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoUnidades = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar las unidades')),
      );
    }
  }

  @override
  void dispose() {
    _importeController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarPeriodo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodo,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _periodo = picked);
    }
  }

  Future<void> _seleccionarFechaVenc() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaVenc,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fechaVenc = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná una unidad o GLOBAL')),
      );
      return;
    }

    final importe = double.tryParse(
      _importeController.text.replaceAll(',', '.'),
    );
    if (importe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importe inválido')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      if (_unidadSeleccionada == 'GLOBAL') {
        await _repo.crearExpensasGlobales(
          consorcioId: widget.consorcioId,
          periodo: _periodo,
          importeTotal: importe,
          fechaVenc: _fechaVenc,
        );
      } else {
        await _repo.crearExpensa(
          consorcioId: widget.consorcioId,
          unidadId: _unidadSeleccionada!,
          periodo: _periodo,
          importeTotal: importe,
          fechaVenc: _fechaVenc,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear expensa: $e')));
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidadesItems = [
      const DropdownMenuItem<String>(
        value: 'GLOBAL',
        child: Text('GLOBAL (todas las unidades)'),
      ),
      ..._unidades.map(
        (u) => DropdownMenuItem<String>(
          value: u['id'] as String,
          child: Text((u['codigo'] ?? '').toString()),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva expensa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Unidad',
                  border: OutlineInputBorder(),
                ),
                initialValue: _unidadSeleccionada,
                items: unidadesItems,
                onChanged: _cargandoUnidades
                    ? null
                    : (value) {
                        setState(() {
                          _unidadSeleccionada = value;
                        });
                      },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Periodo'),
                subtitle: Text('${_periodo.month}/${_periodo.year}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: _seleccionarPeriodo,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _importeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Importe total',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Ingresa un importe'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fecha de vencimiento'),
                subtitle: Text(
                  '${_fechaVenc.day}/${_fechaVenc.month}/${_fechaVenc.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFechaVenc,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crear expensa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
