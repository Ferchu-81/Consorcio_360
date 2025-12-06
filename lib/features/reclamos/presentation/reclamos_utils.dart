/// Helpers compartidos para la secciÃ³n de reclamos.
library;

/// Convierte un ENUM tipo "EN_CURSO" a "En Curso".
String formatEnumLabel(String value) {
  if (value.isEmpty) return value;
  return value
      .split('_')
      .map((part) {
        if (part.isEmpty) return '';
        final lower = part.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

/// Convierte un ISO date a formato corto "15 Feb 25".
String formatShortDateFromIso(dynamic value) {
  if (value == null) return '';
  final str = value.toString();
  final dt = DateTime.tryParse(str);
  if (dt == null) {
    return str.split('T').first;
  }
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final dia = dt.day.toString().padLeft(2, '0');
  final mes = meses[dt.month - 1];
  final anio = (dt.year % 100).toString().padLeft(2, '0');
  return '$dia $mes $anio';
}
