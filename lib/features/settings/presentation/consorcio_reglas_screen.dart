import 'package:consorcio_360/features/settings/domain/consorcio_config.dart';
import 'package:flutter/material.dart';
import 'package:consorcio_360/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConsorcioReglasScreen extends StatefulWidget {
  final String consorcioId;

  const ConsorcioReglasScreen({super.key, required this.consorcioId});

  @override
  State<ConsorcioReglasScreen> createState() => _ConsorcioReglasScreenState();
}

class _ConsorcioReglasScreenState extends State<ConsorcioReglasScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  ConsorcioConfig? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<ConsorcioConfig> _fetchConfig(String consorcioId) async {
    final res = await _supabase
        .from('consorcio_config')
        .select()
        .eq('consorcio_id', consorcioId)
        .single();
    return ConsorcioConfig.fromJson(res);
  }

  Future<void> _updateConfig(
    String consorcioId,
    Map<String, dynamic> patch,
  ) async {
    await _supabase
        .from('consorcio_config')
        .update(patch)
        .eq('consorcio_id', consorcioId);
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final config = await _fetchConfig(widget.consorcioId);
      if (!mounted) return;
      setState(() {
        _config = config;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la configuración.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleFlag({
    required bool value,
    required String field,
    required ConsorcioConfig Function(ConsorcioConfig) apply,
  }) async {
    final current = _config;
    if (current == null) return;

    setState(() {
      _saving = true;
      _config = apply(current);
    });

    try {
      await _updateConfig(widget.consorcioId, {field: value});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _config = current;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la regla.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _updateAmenityOwnerNonOccupant(bool enabled) async {
    final config = _config;
    if (config == null) return;

    setState(() => _saving = true);
    try {
      await _supabase.from('consorcio_config').update({
        'permitir_reservas_prop_no_ocupante': enabled,
        'permitir_uso_amenities_prop_no_ocupante': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('consorcio_id', widget.consorcioId);

      setState(() {
        _config = config.copyWith(
          permitirAmenitiesPropNoOcupante: enabled,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reglas del consorcio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loadConfig,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final config = _config;
    if (config == null) {
      return const Scaffold(
        body: Center(child: Text('No hay configuracion disponible.')),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas del consorcio'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(l10n.cfgAmenitiesOwnerNonOccupantTitle),
            subtitle: Text(l10n.cfgAmenitiesOwnerNonOccupantSubtitle),
            value: config.permitirAmenitiesPropNoOcupante,
            onChanged: _saving
                ? null
                : (value) => _updateAmenityOwnerNonOccupant(value),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.cfgOwnerVoteWithoutOccupyingTitle),
            subtitle: Text(l10n.cfgOwnerVoteWithoutOccupyingSubtitle),
            value: config.propietarioPuedeVotarSinOcupar,
            onChanged: _saving
                ? null
                : (value) => _toggleFlag(
                      value: value,
                      field: 'propietario_puede_votar_sin_ocupar',
                      apply: (c) =>
                          c.copyWith(propietarioPuedeVotarSinOcupar: value),
                    ),
          ),
        ],
      ),
    );
  }
}


