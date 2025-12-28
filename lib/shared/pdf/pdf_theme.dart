import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfThemeLoader {
  static pw.ThemeData? _theme;

  static Future<pw.ThemeData> load() async {
    final cached = _theme;
    if (cached != null) return cached;

    final regularData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');

    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );

    _theme = theme;
    return theme;
  }
}
