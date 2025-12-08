import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Operaciones de datos para expensas y pagos asociados.
class ExpensasRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene las expensas de una unidad ordenadas por periodo descendente.
  Future<List<Expensa>> fetchExpensasDeUnidad(String unidadId) async {
    final data = await _supabase
        .from('expensas')
        .select('''
          id,
          consorcio_id,
          unidad_id,
          periodo,
          importe_total,
          estado,
          fecha_venc,
          fecha_emision,
          moneda
        ''')
        .eq('unidad_id', unidadId)
        .neq('estado', 'ANULADA')
        .order('periodo', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);
    return list.map(Expensa.fromMap).toList();
  }

  Future<Expensa?> fetchExpensaPorId(String id) async {
    final data = await _supabase
        .from('expensas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Expensa.fromMap(Map<String, dynamic>.from(data));
  }

  /// Obtiene una expensa por id (alias claro para lectura puntual).
  Future<Expensa> getExpensaPorId(String expensaId) async {
    final data = await _supabase
        .from('expensas')
        .select('''
          id,
          consorcio_id,
          unidad_id,
          periodo,
          importe_total,
          estado,
          fecha_venc,
          fecha_emision,
          moneda
        ''')
        .eq('id', expensaId)
        .single();

    return Expensa.fromMap(Map<String, dynamic>.from(data as Map));
  }

  /// Pagos ya registrados para una expensa.
  Future<List<PagoExpensa>> fetchPagosDeExpensa(String expensaId) async {
    final data = await _supabase
        .from('pagos_expensa')
        .select('''
          *,
          expensa:expensas (periodo, moneda, importe_total)
        ''')
        .eq('expensa_id', expensaId)
        .order('fecha_pago', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);
    return list.map(PagoExpensa.fromMap).toList();
  }

  /// Historial de pagos de una unidad (para la pestaña Pagos).
  Future<List<PagoExpensa>> fetchPagosDeUnidad(String unidadId) async {
    final data = await _supabase
        .from('pagos_expensa')
        .select('''
          *,
          expensa:expensas (periodo, moneda, importe_total)
        ''')
        .eq('unidad_id', unidadId)
        .order('fecha_pago', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);
    return list.map(PagoExpensa.fromMap).toList();
  }

  /// Listado para administradores: expensas filtradas por consorcio/unidad/estado/rango.
  Future<List<Expensa>> fetchExpensasAdmin({
    required String consorcioId,
    String? unidadId,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    dynamic query = _supabase
        .from('expensas')
        .select('''
          id,
          consorcio_id,
          unidad_id,
          periodo,
          importe_total,
          estado,
          fecha_venc,
          fecha_emision,
          moneda
        ''')
        .eq('consorcio_id', consorcioId)
        .order('periodo', ascending: false);

    if (unidadId != null && unidadId.isNotEmpty) {
      query = query.eq('unidad_id', unidadId);
    }

    if (estado != null && estado.isNotEmpty && estado != 'TODOS') {
      query = query.eq('estado', estado);
    }

    if (desde != null) {
      final inicioMes = DateTime(desde.year, desde.month, 1);
      query = query.gte('periodo', inicioMes.toIso8601String());
    }

    if (hasta != null) {
      final finMes = DateTime(hasta.year, hasta.month + 1, 0);
      query = query.lte('periodo', finMes.toIso8601String());
    }

    final data = await query;
    final list = List<Map<String, dynamic>>.from(data as List);
    return list.map(Expensa.fromMap).toList();
  }

  /// Devuelve unidades de un consorcio para armar filtros en la vista admin.
  Future<List<Map<String, dynamic>>> fetchUnidadesDeConsorcio(
    String consorcioId,
  ) async {
    final data = await _supabase
        .from('unidades')
        .select('id, codigo')
        .eq('consorcio_id', consorcioId)
        .order('codigo', ascending: true);

    final unidades = List<Map<String, dynamic>>.from(data);
    // Asegura no duplicar la opción GLOBAL que se agrega manualmente en la UI.
    return unidades
        .where(
          (u) =>
              (u['id']?.toString().toUpperCase() ?? '') != 'GLOBAL' &&
              (u['codigo']?.toString().toUpperCase() ?? '') != 'GLOBAL',
        )
        .toList();
  }

  /// Inserta pago manual de demo y marca la expensa como pagada.
  Future<void> marcarComoPagadaDemo({
    required Expensa expensa,
    required String consorcioId,
    required String unidadId,
  }) async {
    await _supabase.from('pagos_expensa').insert({
      'expensa_id': expensa.id,
      'consorcio_id': consorcioId,
      'unidad_id': unidadId,
      'importe': expensa.importeTotal,
      'medio_pago': 'EFECTIVO',
      'estado_pago': 'APROBADO',
      'observaciones': 'Pago simulado (demo sin Mercado Pago)',
    });

    await _supabase
        .from('expensas')
        .update({'estado': 'PAGADA'})
        .eq('id', expensa.id);
  }

  /// Actualiza solo el estado de una expensa (para admin).
  Future<void> actualizarEstadoExpensa({
    required String expensaId,
    required String nuevoEstado,
  }) async {
    const estadosPermitidos = <String>{
      'PENDIENTE',
      'PAGADA',
      'VENCIDA',
      'PARCIAL',
      'ANULADA',
    };

    if (!estadosPermitidos.contains(nuevoEstado)) {
      throw ArgumentError('Estado de expensa no valido: $nuevoEstado');
    }

    await _supabase
        .from('expensas')
        .update({'estado': nuevoEstado})
        .eq('id', expensaId);
  }

  /// Crea una expensa manual (MVP admin).
  Future<void> crearExpensa({
    required String consorcioId,
    required String unidadId,
    required DateTime periodo,
    required double importeTotal,
    required DateTime fechaVenc,
  }) async {
    await _supabase.from('expensas').insert({
      'consorcio_id': consorcioId,
      'unidad_id': unidadId,
      'periodo': DateTime(periodo.year, periodo.month, 1).toIso8601String(),
      'importe_total': importeTotal,
      'estado': 'PENDIENTE',
      'fecha_venc': fechaVenc.toIso8601String(),
    });
  }

  /// Crea una expensa para cada unidad del consorcio (caso GLOBAL).
  Future<void> crearExpensasGlobales({
    required String consorcioId,
    required DateTime periodo,
    required double importeTotal,
    required DateTime fechaVenc,
  }) async {
    final unidades = await _supabase
        .from('unidades')
        .select('id')
        .eq('consorcio_id', consorcioId);

    final unidadesList = List<Map<String, dynamic>>.from(
      unidades as List<dynamic>,
    );
    if (unidadesList.isEmpty) return;

    final periodoIso = DateTime(periodo.year, periodo.month, 1)
        .toIso8601String();
    final vencIso = fechaVenc.toIso8601String();

    final data = unidadesList
        .map(
          (u) => {
            'consorcio_id': consorcioId,
            'unidad_id': u['id'] as String,
            'periodo': periodoIso,
            'importe_total': importeTotal,
            'estado': 'PENDIENTE',
            'fecha_venc': vencIso,
          },
        )
        .toList();

    await _supabase.from('expensas').insert(data);
  }
}
