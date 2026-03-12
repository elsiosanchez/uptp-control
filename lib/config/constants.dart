class AppConstants {
  // Colecciones Firestore (top-level)
  static const String colUsers = 'users';
  static const String colSecciones = 'secciones';

  // Subcolecciones
  static const String subColMaterias = 'materias';
  static const String subColEvaluaciones = 'evaluaciones';
  static const String subColEstudiantes = 'estudiantes';
  static const String subColNotas = 'notas';

  // Turnos
  static const List<String> turnos = [
    'Mañana',
    'Tarde',
    'Noche',
  ];

  // Rol admin
  static const String rolAdmin = 'admin';

  // Rango de notas
  static const double notaMinima = 0.0;
  static const double notaMaxima = 20.0;
  static const double notaAprobatoria = 10.0;
  static const double notaRegular = 7.0;
}
