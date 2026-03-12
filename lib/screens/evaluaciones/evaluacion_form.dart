import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/evaluacion_model.dart';
import '../../providers/evaluacion_provider.dart';

class EvaluacionForm extends StatefulWidget {
  const EvaluacionForm({super.key});

  @override
  State<EvaluacionForm> createState() => _EvaluacionFormState();
}

class _EvaluacionFormState extends State<EvaluacionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _porcentajeController = TextEditingController();
  final _descripcionController = TextEditingController();

  late String _seccionId;
  late String _materiaId;
  EvaluacionModel? _evalEdit;
  DateTime? _fecha;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _evalEdit = args['evaluacion'] as EvaluacionModel?;
      if (_evalEdit != null) {
        _nombreController.text = _evalEdit!.nombre;
        _porcentajeController.text =
            _evalEdit!.porcentaje.toStringAsFixed(0);
        _descripcionController.text = _evalEdit!.descripcion ?? '';
        _fecha = _evalEdit!.fecha;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _porcentajeController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EvaluacionProvider>();
    final porcentaje = double.parse(_porcentajeController.text.trim());

    // Validar que no exceda 100%
    final totalActual = provider.porcentajeTotal;
    final totalNuevo = _evalEdit != null
        ? totalActual - _evalEdit!.porcentaje + porcentaje
        : totalActual + porcentaje;

    if (totalNuevo > 100.01) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'El total sería ${totalNuevo.toStringAsFixed(1)}%. Máximo 100%.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final descripcion = _descripcionController.text.trim();
    bool ok;

    if (_evalEdit == null) {
      final nueva = EvaluacionModel(
        id: '',
        nombre: _nombreController.text.trim(),
        porcentaje: porcentaje,
        fecha: _fecha,
        descripcion: descripcion.isEmpty ? null : descripcion,
        orden: provider.evaluaciones.length + 1,
      );
      ok = await provider.addEvaluacion(_seccionId, _materiaId, nueva);
    } else {
      ok = await provider.updateEvaluacion(_seccionId, _materiaId,
          _evalEdit!.id, {
        'nombre': _nombreController.text.trim(),
        'porcentaje': porcentaje,
        'fecha': _fecha,
        'descripcion': descripcion.isEmpty ? null : descripcion,
      });
    }

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_evalEdit == null
                ? 'Evaluación creada'
                : 'Evaluación actualizada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _evalEdit != null;
    final provider = context.watch<EvaluacionProvider>();
    final disponible = 100 -
        provider.porcentajeTotal +
        (_evalEdit?.porcentaje ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Evaluación' : 'Nueva Evaluación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Porcentaje disponible: ${disponible.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la evaluación',
                  hintText: 'Ej: Parcial 1',
                  prefixIcon: Icon(Icons.assignment_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _porcentajeController,
                decoration: const InputDecoration(
                  labelText: 'Porcentaje (%)',
                  hintText: 'Ej: 30',
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obligatorio';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0 || n > 100) {
                    return 'Debe ser entre 1 y 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha (opcional)',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fecha != null
                        ? '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                        color:
                            _fecha != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Breve descripción',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child:
                      Text(isEditing ? 'Actualizar' : 'Crear Evaluación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
