import 'package:consorcio_360/data/models/expensa.dart';
import 'package:consorcio_360/data/models/pago_expensa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Operaciones de datos para expensas y pagos asociados.
class ExpensasRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Obtiene las expensas de una unidad ordenadas por periodo descendente.
  Future<List<Expensa>> fetchExpensasDeUnidad(String unidadId) async {
    final data = await _client
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
    final data = await _client
        .from('expensas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Expensa.fromMap(Map<String, dynamic>.from(data));
  }

  /// Obtiene una expensa por id (alias claro para lectura puntual).
  Future<Expensa> getExpensaPorId(String expensaId) async {
    final data = await _client
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
    final data = await _client
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
    final data = await _client
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

  // PAGOS - MORADOR: pagos de una unidad específica
  Future<List<PagoExpensa>> fetchPagosMorador({
    required String unidadId,
  }) async {
    final data = await _client
        .from('pagos_expensa')
        .select('''
          id,
          expensa_id,
          consorcio_id,
          unidad_id,
          fecha_pago,
          importe,
          medio_pago,
          estado_pago,
          ref_mp,
          observaciones,
          created_at,
          expensas (
            periodo,
            estado,
            fecha_venc,
            importe_total,
            moneda
          )
        ''')
        .eq('unidad_id', unidadId)
        .order('fecha_pago', ascending: false);

    final list = (data as List)
        .map((row) => PagoExpensa.fromMap(row as Map<String, dynamic>))
        .toList();

    return list;
  }

  // PAGOS - ADMIN: todos los pagos del consorcio (opcional filtrar por unidad)
  Future<List<PagoExpensa>> fetchPagosAdmin({
    required String consorcioId,
    String? unidadId,
  }) async {
    var query = _client.from('pagos_expensa').select('''
          id,
          expensa_id,
          consorcio_id,
          unidad_id,
          fecha_pago,
          importe,
          medio_pago,
          estado_pago,
          ref_mp,
          observaciones,
          created_at,
          expensas (
            periodo,
            estado,
            fecha_venc,
            importe_total,
            moneda
          )
        ''').eq('consorcio_id', consorcioId);

    // Si se pasa una unidad, filtramos; si no, traemos todas
    if (unidadId != null) {
      query = query.eq('unidad_id', unidadId);
    }

    final data = await query.order('fecha_pago', ascending: false);

    final list = (data as List)
        .map((row) => PagoExpensa.fromMap(row as Map<String, dynamic>))
        .toList();

    return list;
  }

  /// Listado para administradores: expensas filtradas por consorcio/unidad/estado/rango.
  Future<List<Expensa>> fetchExpensasAdmin({
    required String consorcioId,
    String? unidadId,
    String? estado,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    dynamic query = _client
        .from('expensas')
        .select(
          '''
          id,
          consorcio_id,
          unidad_id,
          periodo,
          importe_total,
          estado,
          fecha_venc,
          fecha_emision,
          moneda,
          unidades (codigo)
          ''',
        )
        .eq('consorcio_id', consorcioId);

    if (unidadId != null) {
      query = query.eq('unidad_id', unidadId);
    }

    if (estado != null && estado.isNotEmpty) {
      query = query.eq('estado', estado);
    }

    if (desde != null) {
      query = query.gte(
        'periodo',
        DateTime(desde.year, desde.month, 1).toIso8601String(),
      );
    }

    if (hasta != null) {
      query = query.lte(
        'periodo',
        DateTime(hasta.year, hasta.month, 1).toIso8601String(),
      );
    }

    query = query.order('periodo', ascending: false);

    final res = await query;
    final list = List<Map<String, dynamic>>.from(res as List);

    return list.map((row) => Expensa.fromMap(row)).toList();
  }

  /// Devuelve unidades de un consorcio para armar filtros en la vista admin.
  Future<List<Map<String, dynamic>>> fetchUnidadesDeConsorcio(
    String consorcioId,
  ) async {
    final data = await _client
        .from('unidades')
        .select('id, codigo')
        .eq('consorcio_id', consorcioId)
        .order('codigo');

    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Inserta pago manual de demo y marca la expensa como pagada.
  Future<void> marcarExpensaComoPagadaDemo({
    required String expensaId,
    required String consorcioId,
    required String unidadId,
    required double importe,
  }) async {
    await _client.from('pagos_expensa').insert({
      'expensa_id': expensaId,
      'consorcio_id': consorcioId,
      'unidad_id': unidadId,
      'importe': importe,
      'medio_pago': 'EFECTIVO',
      'estado_pago': 'APROBADO',
      'observaciones': 'Pago registrado manualmente (demo)',
    });

    await _client
        .from('expensas')
        .update({'estado': 'PAGADA'})
        .eq('id', expensaId);
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

    await _client
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
    await _client.from('expensas').insert({
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
    final res = await _client
        .from('unidades')
        .select('id')
        .eq('consorcio_id', consorcioId);

    final unidades = List<Map<String, dynamic>>.from(res as List);

    if (unidades.isEmpty) return;

    final data = unidades
        .map(
          (u) => {
            'consorcio_id': consorcioId,
            'unidad_id': u['id'] as String,
            'periodo':
                DateTime(periodo.year, periodo.month, 1).toIso8601String(),
            'importe_total': importeTotal,
            'estado': 'PENDIENTE',
            'fecha_venc': fechaVenc.toIso8601String(),
          },
        )
        .toList();

    await _client.from('expensas').insert(data);
  }
}
