import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_theme.dart';
import '../../services/excel_import_service.dart';
import '../../services/firestore_service.dart';

enum _ImportState { seleccion, procesando, preview, importando, resultado }

class ImportEstudiantesScreen extends StatefulWidget {
  const ImportEstudiantesScreen({super.key});

  @override
  State<ImportEstudiantesScreen> createState() =>
      _ImportEstudiantesScreenState();
}

class _ImportEstudiantesScreenState extends State<ImportEstudiantesScreen> {
  final _excelService = ExcelImportService();
  final _firestoreService = FirestoreService();

  _ImportState _state = _ImportState.seleccion;
  ImportResult? _result;
  int _importados = 0;
  String? _errorMsg;

  late String _seccionId;
  late String _materiaId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materiaId = args['materiaId'] as String;
      _initialized = true;
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo leer el archivo'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Check file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El archivo excede 5MB'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      setState(() => _state = _ImportState.procesando);

      // Parse Excel
      final result = _excelService.parseExcelFile(file.bytes!);

      if (result.todos.isEmpty) {
        setState(() {
          _state = _ImportState.seleccion;
          _errorMsg = 'No se encontraron datos en el archivo';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMsg!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Check duplicates against Firestore
      final cedulasExistentes =
          await _firestoreService.getCedulasExistentes(_seccionId, _materiaId);
      _excelService.checkDuplicatesAgainstExisting(result, cedulasExistentes);

      setState(() {
        _result = result;
        _state = _ImportState.preview;
      });
    } catch (e) {
      setState(() => _state = _ImportState.seleccion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al leer archivo: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _ejecutarImportacion() async {
    if (_result == null) return;

    final validos = _result!.validos;
    if (validos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay estudiantes validos para importar'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _state = _ImportState.importando);

    try {
      final estudiantes = validos.map((e) => e.toEstudiante()).toList();
      _importados = await _firestoreService.importarEstudiantesBatch(
        _seccionId,
        _materiaId,
        estudiantes,
      );
      setState(() => _state = _ImportState.resultado);
    } catch (e) {
      setState(() => _state = _ImportState.preview);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _descargarPlantilla() async {
    try {
      final bytes = _excelService.generarPlantilla();

      if (kIsWeb) {
        // On web, use file_picker to save or just share
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Plantilla generada. Usa "Compartir" para descargar.'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/plantilla_estudiantes.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Plantilla de Importacion de Estudiantes',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Estudiantes')),
      body: switch (_state) {
        _ImportState.seleccion => _buildSeleccion(),
        _ImportState.procesando => _buildProcesando(),
        _ImportState.preview => _buildPreview(),
        _ImportState.importando => _buildImportando(),
        _ImportState.resultado => _buildResultado(),
      },
    );
  }

  Widget _buildSeleccion() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.colorEstudiantes.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.upload_file,
                  size: 48, color: AppTheme.colorEstudiantes),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importa estudiantes desde\nun archivo Excel (.xlsx)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _descargarPlantilla,
              icon: const Icon(Icons.download),
              label: const Text('Descargar plantilla'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _seleccionarArchivo,
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar archivo'),
            ),
            const SizedBox(height: 24),
            Text(
              'Formatos: .xlsx\nTamano maximo: 5MB',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcesando() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Leyendo archivo Excel...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final result = _result!;
    return Column(
      children: [
        // Summary card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen de importacion',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'Total encontrados',
                  value: '${result.todos.length}',
                  color: Colors.grey,
                ),
                _SummaryRow(
                  label: 'Validos',
                  value: '${result.totalValidos}',
                  color: AppTheme.successColor,
                  icon: Icons.check_circle,
                ),
                if (result.totalErrores > 0)
                  _SummaryRow(
                    label: 'Con errores',
                    value: '${result.totalErrores}',
                    color: AppTheme.errorColor,
                    icon: Icons.error,
                  ),
                if (result.totalDuplicados > 0)
                  _SummaryRow(
                    label: 'Duplicados',
                    value: '${result.totalDuplicados}',
                    color: AppTheme.warningColor,
                    icon: Icons.warning,
                  ),
              ],
            ),
          ),
        ),
        // Detail list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: result.todos.length,
            itemBuilder: (context, index) {
              final est = result.todos[index];
              final icon = switch (est.status) {
                ImportStatus.ok => Icons.check_circle,
                ImportStatus.error => Icons.error,
                ImportStatus.duplicado => Icons.warning,
              };
              final color = switch (est.status) {
                ImportStatus.ok => AppTheme.successColor,
                ImportStatus.error => AppTheme.errorColor,
                ImportStatus.duplicado => AppTheme.warningColor,
              };
              return Card(
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(
                    est.status == ImportStatus.ok
                        ? '${est.nombre} ${est.apellido}'
                        : 'Fila ${est.filaExcel}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    est.status == ImportStatus.ok
                        ? est.cedula
                        : est.errorMsg ?? 'Error desconocido',
                    style: TextStyle(
                        color:
                            est.status != ImportStatus.ok ? color : null),
                  ),
                ),
              );
            },
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      result.totalValidos > 0 ? _ejecutarImportacion : null,
                  icon: const Icon(Icons.upload),
                  label: Text('Importar ${result.totalValidos} estudiantes'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    setState(() => _state = _ImportState.seleccion),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportando() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Importando estudiantes...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 48, color: AppTheme.successColor),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importacion completada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '$_importados estudiantes importados',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: color)),
          const Spacer(),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
