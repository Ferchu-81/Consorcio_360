import 'package:consorcio_360/bases_legales/data/base_legal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasesLegalesRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<BaseLegal>> obtenerBasesLegalesDeConsorcio(
    String consorcioId,
  ) async {
    final res = await _client
        .from('bases_legales')
        .select()
        .or('consorcio_id.eq.$consorcioId,consorcio_id.is.null')
        .order('categoria', ascending: true)
        .order('titulo', ascending: true);

    return (res as List<dynamic>)
        .map((e) => BaseLegal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
