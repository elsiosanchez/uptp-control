import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/estudiante_model.dart';
import '../../models/evaluacion_model.dart';
import '../../models/nota_model.dart';
import '../../services/firestore_service.dart';

class NotasEstudianteScreen extends StatefulWidget {
  const NotasEstudianteScreen({super.key});

  @override
  State<NotasEstudianteScreen> createState() => _NotasEstudianteScreenState();
}

class _NotasEstudianteScreenState extends State<NotasEstudianteScreen> {
  final _service = FirestoreService();
  bool _initialized = false;
  bool _loading = true;
  bool _saving = false;

  late String _seccionId;
  late String _materiaId;
  late EstudianteModel _estudiante;

  List<EvaluacionModel> _evaluaciones = [];
  Map<String, NotaModel> _notasPorEval = {}; // evaluacionId → nota
  Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _estudiante = args['estudiante'] as EstudianteModel;
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      // Cargar evaluaciones
      final evalsSnap =
          await _service.getEvaluaciones(_seccionId, _materiaId).first;
      // Cargar notas del estudiante
      final notasSnap = await _service
          .getNotasByEstudiante(_seccionId, _materiaId, _estudiante.id)
          .first;

      final notasMap = <String, NotaModel>{};
      for (final nota in notasSnap) {
        notasMap[nota.evaluacionId] = nota;
      }

      final controllers = <String, TextEditingController>{};
      for (final eval in evalsSnap) {
        final nota = notasMap[eval.id];
        controllers[eval.id] = TextEditingController(
          text: nota != null ? nota.calificacion.toStringAsFixed(1) : '',
        );
      }

      setState(() {
        _evaluaciones = evalsSnap;
        _notasPorEval = notasMap;
        _controllers = controllers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  double _calcularNotaFinal() {
    double total = 0;
    for (final eval in _evaluaciones) {
      final nota = _notasPorEval[eval.id];
      if (nota != null) {
        total += nota.calificacion * eval.porcentaje / 100;
      }
    }
    return total;
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    try {
      for (final eval in _evaluaciones) {
        final text = _controllers[eval.id]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        final cal = double.tryParse(text);
        if (cal == null || cal < AppConstants.notaMinima || cal > AppConstants.notaMaxima) continue;

        final nota = NotaModel(
          id: '',
          estudianteId: _estudiante.id,
          evaluacionId: eval.id,
          calificacion: cal,
          observacion: null,
        );
        await _service.addOrUpdateNota(_seccionId, _materiaId, nota);
      }

      // Recargar notas
      final notasSnap = await _service
          .getNotasByEstudiante(_seccionId, _materiaId, _estudiante.id)
          .first;
      final notasMap = <String, NotaModel>{};
      for (final nota in notasSnap) {
        notasMap[nota.evaluacionId] = nota;
      }

      setState(() {
        _notasPorEval = notasMap;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notas guardadas'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notaFinal = _calcularNotaFinal();
    final aprobado = notaFinal >= AppConstants.notaAprobatoria;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estudiante.nombreCompleto),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (aprobado
                            ? AppTheme.successColor
                            : AppTheme.errorColor)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (aprobado
                                ? AppTheme.successColor
                                : AppTheme.errorColor)
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nota Final Ponderada',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(
                            aprobado ? 'APROBADO' : 'REPROBADO',
                            style: TextStyle(
                              color: aprobado
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        notaFinal.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorNota(notaFinal),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de evaluaciones con notas
                Expanded(
                  child: _evaluaciones.isEmpty
                      ? const Center(
                          child: Text('No hay evaluaciones configuradas',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _evaluaciones.length,
                          itemBuilder: (context, index) {
                            final eval = _evaluaciones[index];
                            final controller = _controllers[eval.id]!;
                            final nota = _notasPorEval[eval.id];
                            final aporte = nota != null
                                ? nota.calificacion * eval.porcentaje / 100
                                : 0.0;

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(eval.nombre,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          Text(
                                            '${eval.porcentaje.toStringAsFixed(0)}% · Aporte: ${aporte.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        controller: controller,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: '0-20',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 10),
                                          filled: true,
                                          fillColor: nota != null
                                              ? AppTheme.colorNota(
                                                      nota.calificacion)
                                                  .withOpacity(0.1)
                                              : null,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: nota != null
                                              ? AppTheme.colorNota(
                                                  nota.calificacion)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Botón guardar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _guardar,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                          _saving ? 'Guardando...' : 'Guardar Notas'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
