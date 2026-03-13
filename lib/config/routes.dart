import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/secciones/secciones_screen.dart';
import '../screens/secciones/seccion_form.dart';
import '../screens/secciones/seccion_detail_screen.dart';
import '../screens/materias/materia_form.dart';
import '../screens/materias/materia_detail_screen.dart';
import '../screens/evaluaciones/evaluacion_form.dart';
import '../screens/estudiantes/estudiante_form.dart';
import '../screens/estudiantes/import_estudiantes_screen.dart';
import '../screens/notas/notas_estudiante_screen.dart';
import '../screens/notas/carga_masiva_screen.dart';
import '../screens/notas/boletin_screen.dart';
import '../screens/notas/resumen_materia_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String secciones = '/secciones';
  static const String seccionesForm = '/secciones/form';
  static const String seccionesDetail = '/secciones/detail';
  static const String materiasForm = '/materias/form';
  static const String materiaDetail = '/materias/detail';
  static const String evaluacionForm = '/evaluaciones/form';
  static const String estudianteForm = '/estudiantes/form';
  static const String notasEstudiante = '/notas/estudiante';
  static const String cargaMasiva = '/notas/carga-masiva';
  static const String boletin = '/notas/boletin';
  static const String resumenMateria = '/notas/resumen';
  static const String importEstudiantes = '/estudiantes/importar';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (_) => const LoginScreen(),
      home: (_) => const HomeScreen(),
      secciones: (_) => const SeccionesScreen(),
      seccionesForm: (_) => const SeccionForm(),
      seccionesDetail: (_) => const SeccionDetailScreen(),
      materiasForm: (_) => const MateriaForm(),
      materiaDetail: (_) => const MateriaDetailScreen(),
      evaluacionForm: (_) => const EvaluacionForm(),
      estudianteForm: (_) => const EstudianteForm(),
      notasEstudiante: (_) => const NotasEstudianteScreen(),
      cargaMasiva: (_) => const CargaMasivaScreen(),
      boletin: (_) => const BoletinScreen(),
      resumenMateria: (_) => const ResumenMateriaScreen(),
      importEstudiantes: (_) => const ImportEstudiantesScreen(),
    };
  }
}
