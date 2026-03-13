import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/evaluacion_model.dart';
import '../../models/nota_model.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';

class BoletinScreen extends StatefulWidget {
  const BoletinScreen({super.key});

  @override
  State<BoletinScreen> createState() => _BoletinScreenState();
}

class _BoletinScreenState extends State<BoletinScreen> {
  final _service = FirestoreService();
  bool _initialized = false;
  bool _loading = true;

  late String _seccionId;
  late String _materiaId;
  late String _estudianteId;
  late String _estudianteNombre;
  String _estudianteCedula = '';
  String _seccionNombre = '';
  String _materiaNombre = '';

  List<EvaluacionModel> _evaluaciones = [];
  Map<String, NotaModel> _notasPorEval = {};
  double _notaFinal = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _estudianteId = args['estudianteId'] as String;
      _estudianteNombre = args['estudianteNombre'] as String;
      _estudianteCedula = (args['estudianteCedula'] as String?) ?? '';
      _seccionNombre = (args['seccionNombre'] as String?) ?? '';
      _materiaNombre = (args['materiaNombre'] as String?) ?? '';
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final evals =
          await _service.getEvaluaciones(_seccionId, _materiaId).first;
      final notas = await _service
          .getNotasByEstudiante(_seccionId, _materiaId, _estudianteId)
          .first;

      final notasMap = <String, NotaModel>{};
      for (final n in notas) {
        notasMap[n.evaluacionId] = n;
      }

      double total = 0;
      for (final e in evals) {
        final n = notasMap[e.id];
        if (n != null) {
          total += n.calificacion * e.porcentaje / 100;
        }
      }

      setState(() {
        _evaluaciones = evals;
        _notasPorEval = notasMap;
        _notaFinal = total;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final materiaResumen = MateriaResumenPdf(
        nombre: _materiaNombre.isNotEmpty ? _materiaNombre : 'Materia',
        evaluaciones: _evaluaciones.map((eval) {
          final nota = _notasPorEval[eval.id];
          return EvalNotaPdf(
            nombre: eval.nombre,
            porcentaje: eval.porcentaje,
            nota: nota?.calificacion,
          );
        }).toList(),
        notaFinal: _notaFinal,
      );

      final doc = await PdfService().generarBoletinEstudiante(
        estudianteNombre: _estudianteNombre,
        estudianteCedula: _estudianteCedula,
        seccionNombre: _seccionNombre,
        materias: [materiaResumen],
        promedioGeneral: _notaFinal,
      );
      await Printing.layoutPdf(
        onLayout: (format) => doc.save(),
        name: 'Boletin_$_estudianteNombre',
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
    final aprobado = _notaFinal >= AppConstants.notaAprobatoria;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boletín'),
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
                  // Info estudiante
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.colorEstudiantes,
                            child: Text(
                              _estudianteNombre.isNotEmpty
                                  ? _estudianteNombre[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_estudianteNombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nota final
                  Card(
                    margin: EdgeInsets.zero,
                    color: (aprobado
                            ? AppTheme.successColor
                            : AppTheme.errorColor)
                        .withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('NOTA FINAL',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(
                                aprobado ? 'APROBADO' : 'REPROBADO',
                                style: TextStyle(
                                  color: aprobado
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _notaFinal.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colorNota(_notaFinal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detalle por evaluación
                  Text('Detalle de Evaluaciones',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ..._evaluaciones.map((eval) {
                    final nota = _notasPorEval[eval.id];
                    final cal = nota?.calificacion ?? 0;
                    final aporte = cal * eval.porcentaje / 100;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(eval.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                      'Peso: ${eval.porcentaje.toStringAsFixed(0)}% · Aporte: ${aporte.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: nota != null
                                    ? AppTheme.colorNota(cal).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                nota != null
                                    ? cal.toStringAsFixed(1)
                                    : 'S/N',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: nota != null
                                      ? AppTheme.colorNota(cal)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
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
