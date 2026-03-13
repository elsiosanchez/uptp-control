import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/evaluacion_model.dart';
import '../models/estudiante_model.dart';
import '../models/nota_model.dart';

class PdfService {
  /// Generate a student report card (boletín) as PDF bytes
  Future<pw.Document> generarBoletinEstudiante({
    required String estudianteNombre,
    required String estudianteCedula,
    required String seccionNombre,
    required List<MateriaResumenPdf> materias,
    required double promedioGeneral,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Boletín de Calificaciones'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          // Student info
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Estudiante: $estudianteNombre',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Cédula: $estudianteCedula',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Text('Sección: $seccionNombre',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Table for each materia
          ...materias.map((mat) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    color: PdfColors.blue100,
                    child: pw.Text(mat.nombre,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  ),
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                    },
                    headers: ['Evaluación', '%', 'Nota', 'Aporte'],
                    data: mat.evaluaciones
                        .map((e) => [
                              e.nombre,
                              '${e.porcentaje.toStringAsFixed(0)}%',
                              e.nota != null
                                  ? e.nota!.toStringAsFixed(1)
                                  : 'S/N',
                              e.nota != null
                                  ? (e.nota! * e.porcentaje / 100)
                                      .toStringAsFixed(2)
                                  : '-',
                            ])
                        .toList(),
                  ),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(6),
                    color: mat.notaFinal >= 10
                        ? PdfColors.green50
                        : PdfColors.red50,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Nota Final: ${mat.notaFinal.toStringAsFixed(2)}  —  ${mat.notaFinal >= 10 ? "APROBADO" : "REPROBADO"}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            color: mat.notaFinal >= 10
                                ? PdfColors.green800
                                : PdfColors.red800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],
              )),
          // General average
          pw.Divider(),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'PROMEDIO GENERAL: ${promedioGeneral.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    color: promedioGeneral >= 10
                        ? PdfColors.green800
                        : PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  /// Generate a materia summary report as PDF bytes
  Future<pw.Document> generarResumenMateria({
    required String materiaNombre,
    required String seccionNombre,
    required List<EvaluacionModel> evaluaciones,
    required List<EstudianteModel> estudiantes,
    required List<NotaModel> notas,
    required double promedio,
    required int aprobados,
    required int reprobados,
    required double notaMax,
    required double notaMin,
  }) async {
    final pdf = pw.Document();

    // Build the student-evaluation matrix
    final notasMap = <String, Map<String, double>>{};
    for (final nota in notas) {
      notasMap.putIfAbsent(nota.estudianteId, () => {});
      notasMap[nota.estudianteId]![nota.evaluacionId] = nota.calificacion;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(30),
        header: (context) =>
            _buildHeader('Resumen de Calificaciones: $materiaNombre'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 8),
          pw.Text('Sección: $seccionNombre',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
          // Stats row
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statCell('Promedio', promedio.toStringAsFixed(2)),
                _statCell('Aprobados',
                    '$aprobados (${estudiantes.isNotEmpty ? (aprobados * 100 ~/ estudiantes.length) : 0}%)'),
                _statCell('Reprobados', '$reprobados'),
                _statCell('Nota Máx', notaMax.toStringAsFixed(1)),
                _statCell('Nota Mín', notaMin.toStringAsFixed(1)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          // Full table
          pw.TableHelper.fromTextArray(
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
            headers: [
              'Estudiante',
              'Cédula',
              ...evaluaciones.map((e) =>
                  '${e.nombre}\n(${e.porcentaje.toStringAsFixed(0)}%)'),
              'Final',
              'Estado',
            ],
            data: estudiantes.map((est) {
              final estNotas = notasMap[est.id] ?? {};
              double notaFinal = 0;
              for (final eval in evaluaciones) {
                final cal = estNotas[eval.id];
                if (cal != null) {
                  notaFinal += cal * eval.porcentaje / 100;
                }
              }
              return [
                est.nombreCompleto,
                est.cedula,
                ...evaluaciones.map((e) {
                  final cal = estNotas[e.id];
                  return cal != null ? cal.toStringAsFixed(1) : '-';
                }),
                notaFinal.toStringAsFixed(2),
                notaFinal >= 10 ? 'APR' : 'REP',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('UPTP Control',
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    final now = DateTime.now();
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado: ${now.day}/${now.month}/${now.year}',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _statCell(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600)),
      ],
    );
  }
}

/// Helper class for boletín generation
class MateriaResumenPdf {
  final String nombre;
  final List<EvalNotaPdf> evaluaciones;
  final double notaFinal;

  MateriaResumenPdf({
    required this.nombre,
    required this.evaluaciones,
    required this.notaFinal,
  });
}

class EvalNotaPdf {
  final String nombre;
  final double porcentaje;
  final double? nota;

  EvalNotaPdf({required this.nombre, required this.porcentaje, this.nota});
}
