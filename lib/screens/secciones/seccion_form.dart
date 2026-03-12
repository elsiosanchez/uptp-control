import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/constants.dart';
import '../../models/seccion_model.dart';
import '../../providers/seccion_provider.dart';

class SeccionForm extends StatefulWidget {
  const SeccionForm({super.key});

  @override
  State<SeccionForm> createState() => _SeccionFormState();
}

class _SeccionFormState extends State<SeccionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _anioController = TextEditingController();

  String _turno = AppConstants.turnos.first;
  SeccionModel? _seccionEdit;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _seccionEdit =
          ModalRoute.of(context)?.settings.arguments as SeccionModel?;
      if (_seccionEdit != null) {
        _nombreController.text = _seccionEdit!.nombre;
        _codigoController.text = _seccionEdit!.codigo;
        _turno = _seccionEdit!.turno;
        _anioController.text = _seccionEdit!.anioEscolar.toString();
      } else {
        _anioController.text = DateTime.now().year.toString();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<SeccionProvider>();
    bool ok;

    if (_seccionEdit == null) {
      final nueva = SeccionModel(
        id: '',
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().toUpperCase(),
        turno: _turno,
        anioEscolar: int.parse(_anioController.text.trim()),
        activo: true,
      );
      ok = await provider.addSeccion(nueva);
    } else {
      ok = await provider.updateSeccion(_seccionEdit!.id, {
        'nombre': _nombreController.text.trim(),
        'codigo': _codigoController.text.trim().toUpperCase(),
        'turno': _turno,
        'anio_escolar': int.parse(_anioController.text.trim()),
      });
    }

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_seccionEdit == null
                ? 'Sección creada exitosamente'
                : 'Sección actualizada'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar. Inténtalo de nuevo.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _seccionEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Sección' : 'Nueva Sección'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la sección',
                  hintText: 'Ej: 1er Año Sección A',
                  prefixIcon: Icon(Icons.class_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: 1A',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _turno,
                decoration: const InputDecoration(
                  labelText: 'Turno',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: AppConstants.turnos
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _turno = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _anioController,
                decoration: const InputDecoration(
                  labelText: 'Año escolar',
                  hintText: 'Ej: 2026',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (int.tryParse(v.trim()) == null) return 'Debe ser un número';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Consumer<SeccionProvider>(
                builder: (_, provider, __) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isEditing ? 'Actualizar' : 'Crear Sección'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
