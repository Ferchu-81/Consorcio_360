import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/state/current_context_notifier.dart';
import 'context_selection_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  int _step = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Paso A: consorcio
  bool _consorcioEsNuevo = false;
  List<Map<String, dynamic>> _consorcios = [];
  String? _consorcioSeleccionadoId;

  final _consorcioNombreController = TextEditingController();
  final _consorcioRazonSocialController = TextEditingController();
  final _consorcioCuitController = TextEditingController();
  final _consorcioDomicilioLegalController = TextEditingController();
  final _consorcioEmailContactoController = TextEditingController();
  final _consorcioTelefonoContactoController = TextEditingController();

  // Paso B: unidad real
  bool _unidadEsNueva = false;
  List<Map<String, dynamic>> _unidades = [];
  String? _unidadSeleccionadaId;

  final _unidadCodigoController = TextEditingController();
  String _unidadTipoSeleccionado = 'DEPARTAMENTO';
  final _unidadCoeficienteController = TextEditingController();
  final _unidadSuperficieController = TextEditingController();
  final _unidadDetalleUbicacionController = TextEditingController();

  // Paso C: roles sobre la unidad real
  bool _rolMorador = true;
  bool _rolPropietario = false;

  @override
  void initState() {
    super.initState();
    _loadConsorcios();
  }

  @override
  void dispose() {
    _consorcioNombreController.dispose();
    _consorcioRazonSocialController.dispose();
    _consorcioCuitController.dispose();
    _consorcioDomicilioLegalController.dispose();
    _consorcioEmailContactoController.dispose();
    _consorcioTelefonoContactoController.dispose();

    _unidadCodigoController.dispose();
    _unidadCoeficienteController.dispose();
    _unidadSuperficieController.dispose();
    _unidadDetalleUbicacionController.dispose();

    super.dispose();
  }

  Future<void> _loadConsorcios() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('consorcios')
          .select('id, nombre, cuit')
          .order('nombre');

      setState(() {
        _consorcios = (data as List<dynamic>).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // No es critico para el onboarding; si falla, igual puede crear uno nuevo
    }
  }

  Future<void> _loadUnidadesParaConsorcio(String consorcioId) async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('unidades')
          .select('id, codigo, tipo_unidad')
          .eq('consorcio_id', consorcioId)
          .neq('tipo_unidad', 'GLOBAL') // ocultamos la unidad de admin
          .order('codigo');

      setState(() {
        _unidades = (data as List<dynamic>).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // idem: no es fatal
    }
  }

  void _goNext() {
    setState(() {
      _errorMessage = null;
    });

    if (_step == 0) {
      // Validar consorcio
      if (_consorcioEsNuevo) {
        if (_consorcioNombreController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Ingresa el nombre del consorcio.';
          });
          return;
        }
        if (_consorcioCuitController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Ingresa el CUIT del consorcio.';
          });
          return;
        }
      } else {
        if (_consorcioSeleccionadoId == null) {
          setState(() {
            _errorMessage = 'Selecciona un consorcio existente.';
          });
          return;
        }
      }
      setState(() {
        _step = 1;
      });
      if (!_consorcioEsNuevo && _consorcioSeleccionadoId != null) {
        _loadUnidadesParaConsorcio(_consorcioSeleccionadoId!);
      }
    } else if (_step == 1) {
      // Validar unidad real (por ahora siempre pedimos una)
      if (_unidadEsNueva) {
        if (_unidadCodigoController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Ingresa el codigo de la unidad (ej: 3B).';
          });
          return;
        }
      } else {
        if (_unidadSeleccionadaId == null) {
          setState(() {
            _errorMessage = 'Selecciona una unidad existente.';
          });
          return;
        }
      }
      setState(() {
        _step = 2;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorMessage = null;
        _step -= 1;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Por ahora, exigimos al menos un rol sobre la unidad real
      if (!_rolMorador && !_rolPropietario) {
        setState(() {
          _errorMessage =
              'Selecciona al menos un rol (Propietario) o marcá que ocupas la unidad.';
          _isLoading = false;
        });
        return;
      }

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Sesion no valida. Volve a iniciar sesion.');
      }

      // 1) Determinar / crear consorcio
      String consorcioId;
      if (_consorcioEsNuevo) {
        final insertConsorcio = await supabase
            .from('consorcios')
            .insert({
              'nombre': _consorcioNombreController.text.trim(),
              'razon_social':
                  _consorcioRazonSocialController.text.trim().isEmpty
                  ? null
                  : _consorcioRazonSocialController.text.trim(),
              'cuit': _consorcioCuitController.text.trim(),
              'domicilio_legal':
                  _consorcioDomicilioLegalController.text.trim().isEmpty
                  ? null
                  : _consorcioDomicilioLegalController.text.trim(),
              'email_contacto':
                  _consorcioEmailContactoController.text.trim().isEmpty
                  ? null
                  : _consorcioEmailContactoController.text.trim(),
              'telefono_contacto':
                  _consorcioTelefonoContactoController.text.trim().isEmpty
                  ? null
                  : _consorcioTelefonoContactoController.text.trim(),
            })
            .select()
            .single();

        consorcioId = insertConsorcio['id'] as String;
      } else {
        if (_consorcioSeleccionadoId == null) {
          throw Exception('No se pudo determinar el consorcio.');
        }
        consorcioId = _consorcioSeleccionadoId!;
      }

      // 2) Determinar / crear unidad real (donde vive / es dueno)
      String unidadRealId;
      if (_unidadEsNueva) {
        final coef = double.tryParse(
          _unidadCoeficienteController.text.replaceAll(',', '.'),
        );
        final sup = double.tryParse(
          _unidadSuperficieController.text.replaceAll(',', '.'),
        );

        final insertUnidad = await supabase
            .from('unidades')
            .insert({
              'consorcio_id': consorcioId,
              'codigo': _unidadCodigoController.text.trim(),
              'tipo_unidad': _unidadTipoSeleccionado,
              'coeficiente': coef,
              'superficie_m2': sup,
              'detalle_ubicacion':
                  _unidadDetalleUbicacionController.text.trim().isEmpty
                  ? null
                  : _unidadDetalleUbicacionController.text.trim(),
            })
            .select()
            .single();

        unidadRealId = insertUnidad['id'] as String;
      } else {
        if (_unidadSeleccionadaId == null) {
          throw Exception('No se pudo determinar la unidad.');
        }
        unidadRealId = _unidadSeleccionadaId!;
      }

      // 3) Construir vinculos usuario-unidad-rol
      final List<Map<String, dynamic>> vinculos = [];

      // 3.a) Rol sobre la unidad real (una sola fila, no duplicamos clave)
      String rolUnidad;
      bool esTitular;

      if (_rolPropietario) {
        rolUnidad = 'PROPIETARIO';
        esTitular = true;
      } else {
        rolUnidad = 'MORADOR';
        esTitular = false;
      }

      vinculos.add({
        'usuario_id': user.id,
        'unidad_id': unidadRealId,
        'rol': rolUnidad,
        'es_titular': esTitular,
        // Nuevo modelo (producción): un único vínculo por unidad.
        // - PROPIETARIO puede ser ocupa=true/false.
        // - MORADOR/OCUPANTE ocupa=true.
        'ocupa': _rolPropietario ? _rolMorador : true,
        // Para MORADOR, por defecto lo tratamos como inquilino (configurable luego).
        'es_inquilino': !_rolPropietario,
        'activo': true,
      });

      // 3.b) Si es consorcio nuevo, crear unidad GLOBAL para administracion
      if (_consorcioEsNuevo) {
        // Ya existe unidad GLOBAL para este consorcio?
        final existingGlobal = await supabase
            .from('unidades')
            .select('id')
            .eq('consorcio_id', consorcioId)
            .eq('codigo', 'GLOBAL')
            .maybeSingle();

        String unidadGlobalId;
        if (existingGlobal != null) {
          unidadGlobalId = existingGlobal['id'] as String;
        } else {
          final insertGlobal = await supabase
              .from('unidades')
              .insert({
                'consorcio_id': consorcioId,
                'codigo': 'GLOBAL',
                'tipo_unidad': 'GLOBAL',
                'coeficiente': null,
                'superficie_m2': null,
                'detalle_ubicacion':
                    'Contexto global de administracion del consorcio',
              })
              .select()
              .single();

          unidadGlobalId = insertGlobal['id'] as String;
        }

        vinculos.add({
          'usuario_id': user.id,
          'unidad_id': unidadGlobalId,
          'rol': 'ADMIN_CONSORCIO',
          'es_titular': false,
        });
      }

      if (vinculos.isNotEmpty) {
        await supabase.from('usuarios_unidades').insert(vinculos);
      }

      if (!mounted) return;

      // Limpiamos contexto y vamos a seleccion de contexto
      context.read<CurrentContextNotifier>().clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ContextSelectionScreen()),
        (route) => false,
      );
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('Onboarding Postgrest error: ${e.message}');

      String userMessage =
          'No se pudo guardar la configuracion. Revisa los datos e intenta nuevamente.';

      if (e.message.contains('duplicate key') || e.code == '23505') {
        userMessage =
            'Ya existe un vinculo similar para esta unidad. Proba cambiar los roles o usa la seleccion de contexto.';
      }

      setState(() {
        _errorMessage = userMessage;
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('Onboarding error: $e\n$st');
      setState(() {
        _errorMessage =
            'Ocurrio un error al guardar la configuracion. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------- UI de pasos ----------

  Widget _buildStepHeader() {
    String titulo;
    String subtitulo;

    if (_step == 0) {
      titulo = 'Paso 1 de 3';
      subtitulo = 'Selecciona o crea tu consorcio';
    } else if (_step == 1) {
      titulo = 'Paso 2 de 3';
      subtitulo = 'Selecciona o crea tu unidad funcional';
    } else {
      titulo = 'Paso 3 de 3';
      subtitulo = 'Elige tu rol en la unidad';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildStepConsorcio() {
    return RadioGroup<bool>(
      groupValue: _consorcioEsNuevo,
      onChanged: (value) {
        setState(() {
          _consorcioEsNuevo = value ?? false;
          _errorMessage = null;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<bool>(
            value: false,
            title: const Text('Vincularme a un consorcio existente'),
            subtitle: const Text(
              'Busca tu consorcio en la lista. Ideal si ya esta cargado.',
            ),
          ),
          if (!_consorcioEsNuevo)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Consorcio'),
                items: _consorcios
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(
                          '${c['nombre']}'
                          '${c['cuit'] != null && (c['cuit'] as String).isNotEmpty ? '  CUIT ${c['cuit']}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                initialValue: _consorcioSeleccionadoId,
                onChanged: (value) {
                  setState(() {
                    _consorcioSeleccionadoId = value;
                    _unidades = [];
                    _unidadSeleccionadaId = null;
                    _errorMessage = null;
                  });
                  if (value != null) {
                    _loadUnidadesParaConsorcio(value);
                  }
                },
              ),
            ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            title: const Text('Crear un nuevo consorcio (soy administrador)'),
            subtitle: const Text(
              'Usa esta opcion si tu consorcio todavia no esta en la app.',
            ),
          ),
          if (_consorcioEsNuevo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _consorcioNombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del consorcio',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _consorcioRazonSocialController,
                    decoration: const InputDecoration(
                      labelText: 'Razon social (opcional)',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _consorcioCuitController,
                    decoration: const InputDecoration(labelText: 'CUIT'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _consorcioDomicilioLegalController,
                    decoration: const InputDecoration(
                      labelText: 'Domicilio legal (opcional)',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _consorcioEmailContactoController,
                    decoration: const InputDecoration(
                      labelText: 'Email de contacto (opcional)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _consorcioTelefonoContactoController,
                    decoration: const InputDecoration(
                      labelText: 'Telefono de contacto (opcional)',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepUnidad() {
    return RadioGroup<bool>(
      groupValue: _unidadEsNueva,
      onChanged: (value) {
        setState(() {
          _unidadEsNueva = value ?? false;
          _errorMessage = null;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<bool>(
            value: false,
            title: const Text('Usar una unidad existente'),
            subtitle: const Text('Selecciona tu departamento, cochera, etc.'),
          ),
          if (!_unidadEsNueva)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: _unidades
                    .map(
                      (u) => DropdownMenuItem(
                        value: u['id'] as String,
                        child: Text(
                          '${u['codigo']}'
                          '${u['tipo_unidad'] != null ? ' ${u['tipo_unidad']}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                initialValue: _unidadSeleccionadaId,
                onChanged: (value) {
                  setState(() {
                    _unidadSeleccionadaId = value;
                    _errorMessage = null;
                  });
                },
              ),
            ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            title: const Text('Crear una nueva unidad'),
            subtitle: const Text(
              'Si tu unidad no esta en la lista, podes crearla.',
            ),
          ),
          if (_unidadEsNueva)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _unidadCodigoController,
                    decoration: const InputDecoration(
                      labelText: 'Codigo de unidad (ej: 3B, COCH-1)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de unidad',
                    ),
                    initialValue: _unidadTipoSeleccionado,
                    items: const [
                      DropdownMenuItem(
                        value: 'DEPARTAMENTO',
                        child: Text('Departamento'),
                      ),
                      DropdownMenuItem(value: 'CASA', child: Text('Casa')),
                      DropdownMenuItem(value: 'DUPLEX', child: Text('Duplex')),
                      DropdownMenuItem(
                        value: 'OFICINA',
                        child: Text('Oficina'),
                      ),
                      DropdownMenuItem(
                        value: 'COCHERA',
                        child: Text('Cochera'),
                      ),
                      DropdownMenuItem(
                        value: 'LOCAL',
                        child: Text('Local comercial'),
                      ),
                      DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _unidadTipoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _unidadCoeficienteController,
                    decoration: const InputDecoration(
                      labelText: 'Coeficiente (opcional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _unidadSuperficieController,
                    decoration: const InputDecoration(
                      labelText: 'Superficie (m2) (opcional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _unidadDetalleUbicacionController,
                    decoration: const InputDecoration(
                      labelText: 'Detalle de ubicacion (opcional)',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepRoles() {
    final esConsorcioNuevo = _consorcioEsNuevo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona como participas en esta unidad (podes elegir mas de uno):',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _rolMorador,
            onChanged: (value) {
              setState(() {
                _rolMorador = value ?? false;
              });
            },
            title: const Text('Ocupa la unidad'),
            subtitle: const Text('Vivis o usas diariamente esta unidad.'),
          ),
          CheckboxListTile(
            value: _rolPropietario,
            onChanged: (value) {
              setState(() {
                _rolPropietario = value ?? false;
              });
            },
            title: const Text('Propietario'),
            subtitle: const Text('Sos titular de la unidad.'),
          ),
          const SizedBox(height: 12),
          if (esConsorcioNuevo)
            Row(
              children: const [
                Icon(Icons.admin_panel_settings_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al crear un consorcio nuevo, quedaras registrado como '
                    'Administrador del consorcio de forma automatica.',
                  ),
                ),
              ],
            )
          else
            Row(
              children: const [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El rol de Administrador del consorcio se gestiona despues. '
                    'Por ahora solo definis tu rol como vecino.',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget stepBody;
    if (_step == 0) {
      stepBody = _buildStepConsorcio();
    } else if (_step == 1) {
      stepBody = _buildStepUnidad();
    } else {
      stepBody = _buildStepRoles();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion inicial')),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: stepBody,
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : _goBack,
                    child: Text(_step == 0 ? 'Cancelar' : 'Atras'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _goNext,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_step < 2 ? Icons.arrow_forward : Icons.check),
                    label: Text(
                      _isLoading
                          ? 'Guardando...'
                          : (_step < 2 ? 'Siguiente' : 'Finalizar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
