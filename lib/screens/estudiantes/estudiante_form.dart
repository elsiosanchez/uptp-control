import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/estudiante_model.dart';
import '../../providers/estudiante_provider.dart';

class EstudianteForm extends StatefulWidget {
  const EstudianteForm({super.key});

  @override
  State<EstudianteForm> createState() => _EstudianteFormState();
}

class _EstudianteFormState extends State<EstudianteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();

  late String _seccionId;
  late String _materiaId;
  EstudianteModel? _estEdit;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _estEdit = args['estudiante'] as EstudianteModel?;
      if (_estEdit != null) {
        _nombreController.text = _estEdit!.nombre;
        _apellidoController.text = _estEdit!.apellido;
        _cedulaController.text = _estEdit!.cedula;
        _emailController.text = _estEdit!.email ?? '';
        _telefonoController.text = _estEdit!.telefono ?? '';
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EstudianteProvider>();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim();
    bool ok;

    if (_estEdit == null) {
      final nuevo = EstudianteModel(
        id: '',
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        cedula: _cedulaController.text.trim(),
        email: email.isEmpty ? null : email,
        telefono: telefono.isEmpty ? null : telefono,
        activo: true,
      );
      ok = await provider.addEstudiante(_seccionId, _materiaId, nuevo);
    } else {
      ok = await provider.updateEstudiante(
          _seccionId, _materiaId, _estEdit!.id, {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'cedula': _cedulaController.text.trim(),
        'email': email.isEmpty ? null : email,
        'telefono': telefono.isEmpty ? null : telefono,
      });
    }

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_estEdit == null
                ? 'Estudiante agregado'
                : 'Estudiante actualizado'),
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
    final isEditing = _estEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Estudiante' : 'Nuevo Estudiante'),
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
                  labelText: 'Nombre',
                  hintText: 'Ej: Juan',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  hintText: 'Ej: Pérez',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  hintText: 'Ej: V-12345678',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  hintText: 'Ej: juan@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  hintText: 'Ej: 0412-1234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Actualizar' : 'Agregar Estudiante'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
