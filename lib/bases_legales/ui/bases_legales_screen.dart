import 'package:consorcio_360/bases_legales/data/base_legal.dart';
import 'package:consorcio_360/bases_legales/data/bases_legales_repository.dart';
import 'package:consorcio_360/core/state/current_context_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BasesLegalesScreen extends StatefulWidget {
  final String consorcioId;

  const BasesLegalesScreen({
    super.key,
    required this.consorcioId,
  });

  @override
  State<BasesLegalesScreen> createState() => _BasesLegalesScreenState();
}

class _BasesLegalesScreenState extends State<BasesLegalesScreen> {
  final BasesLegalesRepository _repository = BasesLegalesRepository();
  late Future<List<BaseLegal>> _futureBases;

  @override
  void initState() {
    super.initState();
    _futureBases = _repository.obtenerBasesLegalesDeConsorcio(
      widget.consorcioId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _futureBases = _repository.obtenerBasesLegalesDeConsorcio(
        widget.consorcioId,
      );
    });
    await _futureBases;
  }

  Future<void> _abrirPdf(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el documento.'),
        ),
      );
    }
  }

  Widget _buildSection(String titulo, List<BaseLegal> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...items.map(
          (b) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                b.titulo,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  b.descripcion,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              trailing: const Icon(Icons.picture_as_pdf_outlined),
              onTap: () => _abrirPdf(b.urlPdf),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin =
        context.read<CurrentContextNotifier>().current?.rol == 'ADMIN_CONSORCIO';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bases legales'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<BaseLegal>>(
          future: _futureBases,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se pudieron cargar las bases legales: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final bases = snapshot.data ?? [];
            final consorcioDocs = bases
                .where((b) => b.categoria.toUpperCase() == 'CONSORCIO')
                .toList();
            final legalesDocs = bases
                .where((b) => b.categoria.toUpperCase() == 'LEGAL')
                .toList();

            if (bases.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay documentos cargados para este consorcio.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Text(
                    'Consultá el reglamento del consorcio y las normas vigentes. '
                    'Los PDFs se abren dentro de la app (podés buscar y compartir).',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                _buildSection('Documentos del consorcio', consorcioDocs),
                _buildSection('Legales generales', legalesDocs),
                if (esAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text(
                        'Agregar documento (administrador)',
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'En esta versión, los documentos se cargan desde el panel '
                              'de Supabase. La carga directa desde la app se implementará '
                              'en una etapa posterior.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    color: Colors.indigo.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.indigo.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'En próximas versiones, el administrador podrá cargar y actualizar '
                        'estos documentos directamente desde la app. Hoy se gestionan desde '
                        'el panel de Supabase.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
