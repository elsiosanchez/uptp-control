import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/estudiante_model.dart';

enum ImportStatus { ok, error, duplicado }

class EstudianteImport {
  final String cedula;
  final String nombre;
  final String apellido;
  final String? email;
  final String? telefono;
  final int filaExcel;
  ImportStatus status;
  String? errorMsg;

  EstudianteImport({
    required this.cedula,
    required this.nombre,
    required this.apellido,
    this.email,
    this.telefono,
    required this.filaExcel,
    this.status = ImportStatus.ok,
    this.errorMsg,
  });

  EstudianteModel toEstudiante() => EstudianteModel(
        id: '',
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        email: email,
        telefono: telefono,
        activo: true,
      );
}

class ImportResult {
  final List<EstudianteImport> todos;

  ImportResult({required this.todos});

  List<EstudianteImport> get validos =>
      todos.where((e) => e.status == ImportStatus.ok).toList();
  List<EstudianteImport> get errores =>
      todos.where((e) => e.status == ImportStatus.error).toList();
  List<EstudianteImport> get duplicados =>
      todos.where((e) => e.status == ImportStatus.duplicado).toList();
  int get totalValidos => validos.length;
  int get totalErrores => errores.length;
  int get totalDuplicados => duplicados.length;
}

class ExcelImportService {
  /// Parse an Excel file and extract student data
  /// Expected format: Row 1-3 headers, Row 4 column names, data starts at row 5
  /// Columns: A=Cedula, B=Nombre, C=Apellido, D=Email, E=Telefono
  ImportResult parseExcelFile(Uint8List fileBytes) {
    final excel = Excel.decodeBytes(fileBytes);
    final todos = <EstudianteImport>[];

    // Use first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    // Data starts at row index 4 (row 5 in Excel, 0-indexed)
    // But be flexible - find the first row with data after headers
    int startRow = 4;
    if (sheet.maxRows <= startRow) {
      // Try starting from row 1 if the file is simple
      startRow = 1;
    }

    for (int i = startRow; i < sheet.maxRows; i++) {
      final row = sheet.row(i);

      // Skip completely empty rows
      if (row.every((cell) =>
          cell == null ||
          cell.value == null ||
          cell.value.toString().trim().isEmpty)) {
        continue;
      }

      final cedula = _getCellValue(row, 0);
      final nombre = _getCellValue(row, 1);
      final apellido = _getCellValue(row, 2);
      final email = _getCellValue(row, 3);
      final telefono = _getCellValue(row, 4);

      final import_ = EstudianteImport(
        cedula: cedula,
        nombre: nombre,
        apellido: apellido,
        email: email.isEmpty ? null : email,
        telefono: telefono.isEmpty ? null : telefono,
        filaExcel: i + 1, // 1-indexed for display
      );

      // Validate required fields
      if (cedula.isEmpty) {
        import_.status = ImportStatus.error;
        import_.errorMsg = 'Cedula es requerida';
      } else if (nombre.isEmpty) {
        import_.status = ImportStatus.error;
        import_.errorMsg = 'Nombre es requerido';
      } else if (apellido.isEmpty) {
        import_.status = ImportStatus.error;
        import_.errorMsg = 'Apellido es requerido';
      }

      todos.add(import_);
    }

    // Check for duplicates within the Excel file
    final seen = <String>{};
    for (final est in todos) {
      if (est.status != ImportStatus.ok) continue;
      if (seen.contains(est.cedula.toUpperCase())) {
        est.status = ImportStatus.duplicado;
        est.errorMsg = 'Cedula duplicada en el archivo';
      } else {
        seen.add(est.cedula.toUpperCase());
      }
    }

    return ImportResult(todos: todos);
  }

  /// Check duplicates against existing students in Firestore
  void checkDuplicatesAgainstExisting(
      ImportResult result, List<String> cedulasExistentes) {
    final existentesUpper =
        cedulasExistentes.map((c) => c.toUpperCase()).toSet();
    for (final est in result.todos) {
      if (est.status != ImportStatus.ok) continue;
      if (existentesUpper.contains(est.cedula.toUpperCase())) {
        est.status = ImportStatus.duplicado;
        est.errorMsg = 'Ya existe en la materia';
      }
    }
  }

  /// Generate an empty template Excel file
  Uint8List generarPlantilla() {
    final excel = Excel.createExcel();
    final sheet = excel['Estudiantes'];

    // Row 1: Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('Plantilla de Importacion de Estudiantes');

    // Row 2: Instructions
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue(
            'Complete los datos a partir de la fila 5. No modifique las filas 1-4.');

    // Row 3: Required/Optional
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('Requerido');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        TextCellValue('Requerido');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 2)).value =
        TextCellValue('Requerido');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 2)).value =
        TextCellValue('Opcional');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2)).value =
        TextCellValue('Opcional');

    // Row 4: Column headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('Cedula');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        TextCellValue('Nombre');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3)).value =
        TextCellValue('Apellido');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value =
        TextCellValue('Email');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 3)).value =
        TextCellValue('Telefono');

    // Row 5: Example
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('V-12345678');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value =
        TextCellValue('Juan');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 4)).value =
        TextCellValue('Perez');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 4)).value =
        TextCellValue('juan@email.com');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 4)).value =
        TextCellValue('0412-1234567');

    // Remove the default Sheet1 if it's not our sheet
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return Uint8List.fromList(excel.encode()!);
  }

  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length ||
        row[index] == null ||
        row[index]!.value == null) {
      return '';
    }
    return row[index]!.value.toString().trim();
  }
}
