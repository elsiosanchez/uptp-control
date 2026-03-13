import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/evaluacion_model.dart';
import '../../models/estudiante_model.dart';
import '../../models/nota_model.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';

class ResumenMateriaScreen extends StatefulWidget {
  const ResumenMateriaScreen({super.key});

  @override
  State<ResumenMateriaScreen> createState() => _ResumenMateriaScreenState();
}

class _ResumenMateriaScreenState extends State<ResumenMateriaScreen> {
  final _service = FirestoreService();
  bool _initialized = false;
  bool _loading = true;

  late String _seccionId;
  late String _materiaId;
  late String _materiaNombre;
  String _seccionNombre = '';

  List<EstudianteModel> _estudiantes = [];
  List<EvaluacionModel> _evaluaciones = [];
  List<NotaModel> _todasNotas = [];
  Map<String, double> _notasFinales = {}; // estudianteId → nota final
  double _promedio = 0;
  int _aprobados = 0;
  int _reprobados = 0;
  double _notaMaxima = 0;
  double _notaMinima = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _materiaNombre = args['materiaNombre'] as String;
      _seccionNombre = (args['seccionNombre'] as String?) ?? '';
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final estudiantes =
          await _service.getEstudiantes(_seccionId, _materiaId).first;
      final evaluaciones =
          await _service.getEvaluaciones(_seccionId, _materiaId).first;
      final todasNotas =
          await _service.getAllNotas(_seccionId, _materiaId);

      // Indexar notas: estudianteId → {evaluacionId → nota}
      final notasIndex = <String, Map<String, NotaModel>>{};
      for (final nota in todasNotas) {
        notasIndex
            .putIfAbsent(nota.estudianteId, () => {})
            [nota.evaluacionId] = nota;
      }

      // Calcular nota final por estudiante
      final finales = <String, double>{};
      double sumaTotal = 0;
      int aprobados = 0;
      int reprobados = 0;
      double max = 0;
      double min = 20;

      for (final est in estudiantes) {
        double total = 0;
        final estNotas = notasIndex[est.id] ?? {};
        for (final eval in evaluaciones) {
          final nota = estNotas[eval.id];
          if (nota != null) {
            total += nota.calificacion * eval.porcentaje / 100;
          }
        }
        finales[est.id] = total;
        sumaTotal += total;
        if (total >= AppConstants.notaAprobatoria) {
          aprobados++;
        } else {
          reprobados++;
        }
        if (total > max) max = total;
        if (total < min) min = total;
      }

      setState(() {
        _estudiantes = estudiantes;
        _evaluaciones = evaluaciones;
        _todasNotas = todasNotas;
        _notasFinales = finales;
        _promedio = estudiantes.isNotEmpty
            ? sumaTotal / estudiantes.length
            : 0;
        _aprobados = aprobados;
        _reprobados = reprobados;
        _notaMaxima = max;
        _notaMinima = estudiantes.isNotEmpty ? min : 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final doc = await PdfService().generarResumenMateria(
        materiaNombre: _materiaNombre,
        seccionNombre: _seccionNombre,
        evaluaciones: _evaluaciones,
        estudiantes: _estudiantes,
        notas: _todasNotas,
        promedio: _promedio,
        aprobados: _aprobados,
        reprobados: _reprobados,
        notaMax: _notaMaxima,
        notaMin: _notaMinima,
      );
      await Printing.layoutPdf(
        onLayout: (format) => doc.save(),
        name: 'Resumen_$_materiaNombre',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen: $_materiaNombre'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar PDF',
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Promedio',
                              value: _promedio.toStringAsFixed(2),
                              color: AppTheme.colorNota(_promedio))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatCard(
                              label: 'Aprobados',
                              value: '$_aprobados',
                              color: AppTheme.successColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatCard(
                              label: 'Reprobados',
                              value: '$_reprobados',
                              color: AppTheme.errorColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Nota más alta',
                              value: _notaMaxima.toStringAsFixed(2),
                              color: AppTheme.successColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatCard(
                              label: 'Nota más baja',
                              value: _notaMinima.toStringAsFixed(2),
                              color: AppTheme.errorColor)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _StatCard(
                              label: 'Total',
                              value: '${_estudiantes.length}',
                              color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text('Notas Finales',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Lista de estudiantes con nota final
                  ..._estudiantes.map((est) {
                    final nota = _notasFinales[est.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.colorNota(nota),
                          child: Text(
                            nota.toStringAsFixed(0),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(est.nombreCompleto,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(est.cedula,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          nota.toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.colorNota(nota),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
