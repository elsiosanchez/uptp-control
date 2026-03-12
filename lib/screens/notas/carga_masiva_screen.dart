import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/estudiante_model.dart';
import '../../models/evaluacion_model.dart';
import '../../models/nota_model.dart';
import '../../services/firestore_service.dart';

class CargaMasivaScreen extends StatefulWidget {
  const CargaMasivaScreen({super.key});

  @override
  State<CargaMasivaScreen> createState() => _CargaMasivaScreenState();
}

class _CargaMasivaScreenState extends State<CargaMasivaScreen> {
  final _service = FirestoreService();
  bool _initialized = false;
  bool _loading = true;
  bool _saving = false;

  late String _seccionId;
  late String _materiaId;
  late EvaluacionModel _evaluacion;

  List<EstudianteModel> _estudiantes = [];
  Map<String, NotaModel> _notasExistentes = {}; // estudianteId → nota
  Map<String, TextEditingController> _controllers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _evaluacion = args['evaluacion'] as EvaluacionModel;
      _initialized = true;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final estudiantesSnap =
          await _service.getEstudiantes(_seccionId, _materiaId).first;
      final notasSnap = await _service
          .getNotasByEvaluacion(_seccionId, _materiaId, _evaluacion.id)
          .first;

      final notasMap = <String, NotaModel>{};
      for (final nota in notasSnap) {
        notasMap[nota.estudianteId] = nota;
      }

      final controllers = <String, TextEditingController>{};
      for (final est in estudiantesSnap) {
        final nota = notasMap[est.id];
        controllers[est.id] = TextEditingController(
          text: nota != null ? nota.calificacion.toStringAsFixed(1) : '',
        );
      }

      setState(() {
        _estudiantes = estudiantesSnap;
        _notasExistentes = notasMap;
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

  Future<void> _guardarTodo() async {
    // Validar todas las notas ingresadas
    final notas = <NotaModel>[];
    int sinNota = 0;

    for (final est in _estudiantes) {
      final text = _controllers[est.id]?.text.trim() ?? '';
      if (text.isEmpty) {
        sinNota++;
        continue;
      }
      final cal = double.tryParse(text);
      if (cal == null ||
          cal < AppConstants.notaMinima ||
          cal > AppConstants.notaMaxima) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Nota inválida para ${est.nombreCompleto} (debe ser 0-20)'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
      notas.add(NotaModel(
        id: '',
        estudianteId: est.id,
        evaluacionId: _evaluacion.id,
        calificacion: cal,
        observacion: null,
      ));
    }

    if (notas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay notas para guardar')),
      );
      return;
    }

    // Advertencia si hay estudiantes sin nota
    if (sinNota > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Estudiantes sin nota'),
          content: Text(
              '$sinNota estudiante(s) no tienen nota. ¿Deseas continuar?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar igualmente')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _saving = true);
    try {
      await _service.guardarNotasMasivas(_seccionId, _materiaId, notas);

      // Recargar notas existentes
      final notasSnap = await _service
          .getNotasByEvaluacion(_seccionId, _materiaId, _evaluacion.id)
          .first;
      final notasMap = <String, NotaModel>{};
      for (final nota in notasSnap) {
        notasMap[nota.estudianteId] = nota;
      }

      setState(() {
        _notasExistentes = notasMap;
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notas.length} notas guardadas'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Notas: ${_evaluacion.nombre}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info de evaluación
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.colorNotas.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment,
                          color: AppTheme.colorNotas, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_evaluacion.nombre} — ${_evaluacion.porcentaje.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${_estudiantes.length} estudiantes',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),

                // Lista de estudiantes con campo de nota
                Expanded(
                  child: _estudiantes.isEmpty
                      ? const Center(
                          child: Text('No hay estudiantes inscritos',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _estudiantes.length,
                          itemBuilder: (context, index) {
                            final est = _estudiantes[index];
                            final controller = _controllers[est.id]!;
                            final notaExistente = _notasExistentes[est.id];

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppTheme.colorEstudiantes,
                                      child: Text(
                                        est.apellido.isNotEmpty
                                            ? est.apellido[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(est.nombreCompleto,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14)),
                                          Text(est.cedula,
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
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
                                          fillColor: notaExistente != null
                                              ? AppTheme.colorNota(
                                                      notaExistente
                                                          .calificacion)
                                                  .withOpacity(0.1)
                                              : null,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: notaExistente != null
                                              ? AppTheme.colorNota(
                                                  notaExistente.calificacion)
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
                      onPressed: _saving ? null : _guardarTodo,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving
                          ? 'Guardando...'
                          : 'Guardar Todas las Notas'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
