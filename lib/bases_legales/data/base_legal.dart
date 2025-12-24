class BaseLegal {
  final String? id;
  final String? consorcioId;
  final String categoria;
  final String titulo;
  final String descripcion;
  final String urlPdf;

  BaseLegal({
    this.id,
    this.consorcioId,
    required this.categoria,
    required this.titulo,
    required this.descripcion,
    required this.urlPdf,
  });

  factory BaseLegal.fromJson(Map<String, dynamic> json) {
    return BaseLegal(
      id: json['id'] as String?,
      consorcioId: json['consorcio_id'] as String?,
      categoria: (json['categoria'] as String? ?? '').trim(),
      titulo: (json['titulo'] as String? ?? '').trim(),
      descripcion: (json['descripcion'] as String? ?? '').trim(),
      urlPdf: (json['url_pdf'] as String? ?? '').trim(),
    );
  }
}
