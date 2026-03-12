import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/materia_model.dart';
import '../../providers/materia_provider.dart';

class MateriaForm extends StatefulWidget {
  const MateriaForm({super.key});

  @override
  State<MateriaForm> createState() => _MateriaFormState();
}

class _MateriaFormState extends State<MateriaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _docenteController = TextEditingController();

  late String _seccionId;
  MateriaModel? _materiaEdit;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _seccionId = args['seccionId'] as String;
        _materiaEdit = args['materia'] as MateriaModel?;
        if (_materiaEdit != null) {
          _nombreController.text = _materiaEdit!.nombre;
          _codigoController.text = _materiaEdit!.codigo;
          _docenteController.text = _materiaEdit!.docente ?? '';
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _docenteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MateriaProvider>();
    final docente = _docenteController.text.trim();
    bool ok;

    if (_materiaEdit == null) {
      final nueva = MateriaModel(
        id: '',
        nombre: _nombreController.text.trim(),
        codigo: _codigoController.text.trim().toUpperCase(),
        docente: docente.isEmpty ? null : docente,
        activo: true,
      );
      ok = await provider.addMateria(_seccionId, nueva);
    } else {
      ok = await provider.updateMateria(_seccionId, _materiaEdit!.id, {
        'nombre': _nombreController.text.trim(),
        'codigo': _codigoController.text.trim().toUpperCase(),
        'docente': docente.isEmpty ? null : docente,
      });
    }

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_materiaEdit == null
                ? 'Materia creada exitosamente'
                : 'Materia actualizada'),
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
    final isEditing = _materiaEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Materia' : 'Nueva Materia'),
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
                  labelText: 'Nombre de la materia',
                  hintText: 'Ej: Matemáticas I',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  hintText: 'Ej: MAT-101',
                  prefixIcon: Icon(Icons.tag),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _docenteController,
                decoration: const InputDecoration(
                  labelText: 'Docente (opcional)',
                  hintText: 'Ej: Prof. García',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Actualizar' : 'Crear Materia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
