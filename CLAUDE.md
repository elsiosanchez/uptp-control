# UPTP Control - Contexto del Proyecto

## Qué es este proyecto
App móvil Flutter + Firebase para control de notas estudiantiles. Un solo usuario administrador gestiona secciones, materias, estudiantes y calificaciones.

## Stack
- **Framework:** Flutter 3.x con Dart
- **Backend:** Firebase (Auth, Cloud Firestore)
- **State Management:** Provider
- **Arquitectura:** Capas separadas (models → services → providers → screens)

## Estructura
```
lib/
├── config/          # app_theme.dart, constants.dart, routes.dart
├── models/          # *_model.dart (fromFirestore/toMap)
├── services/        # auth_service.dart, firestore_service.dart
├── providers/       # *_provider.dart (ChangeNotifier + streams Firestore)
├── screens/         # auth/, home/, secciones/, materias/, evaluaciones/, estudiantes/, notas/
├── widgets/         # Componentes reutilizables
└── main.dart        # Entry point con MultiProvider + Firebase.initializeApp
```

## Modelo de Datos (Firestore - Subcolecciones)
```
users/{uid} → nombre, email, rol, activo
secciones/{seccionId} → nombre, codigo, turno, anio_escolar, activo
  └── materias/{materiaId} → nombre, codigo, docente, activo
        ├── evaluaciones/{evaluacionId} → nombre, porcentaje, fecha, orden
        ├── estudiantes/{estudianteId} → nombre, apellido, cedula, email
        └── notas/{notaId} → estudianteId, evaluacionId, calificacion
```

## Comandos
```bash
flutter pub get          # Instalar dependencias
flutter run              # Ejecutar en dispositivo/emulador
flutter run -d chrome    # Ejecutar en web
flutter analyze          # Análisis estático
flutter test             # Ejecutar tests
flutterfire configure    # Reconfigurar Firebase
flutter build apk        # Build de release
```

## Convenciones
- Modelos: `NombreModel` con factory `fromFirestore(DocumentSnapshot)` y método `toMap()`
- Providers: extienden `ChangeNotifier`, exponen streams de Firestore
- Providers con contexto: usan `loadX(seccionId)` para cargar datos de subcolección
- Screens: StatelessWidget cuando es posible, StatefulWidget solo con formularios
- Nombres de archivos: snake_case (ej: `seccion_model.dart`)
- Subcolecciones: definidas en `config/constants.dart` como `subColX`
- Soft delete: campo `activo: false` en vez de borrar documentos
- Notas: rango 0-20, color verde ≥10, naranja ≥7, rojo <7
- Ponderaciones: porcentaje por evaluación, total máximo 100% por materia

## Reglas de negocio
- Cada sección tiene sus propias materias (subcolección)
- Cada materia tiene sus propios estudiantes, evaluaciones y notas (subcolecciones)
- Las evaluaciones tienen porcentaje (%) que debe sumar 100% por materia
- Solo hay un usuario administrador
- El registro de notas es masivo: se muestran todos los estudiantes para una evaluación

## Flujo de navegación
```
Login → Home → Secciones → Detalle Sección → Materias
  → Detalle Materia (tabs: Evaluaciones | Estudiantes)
    → Evaluaciones: crear/editar, tap → carga masiva de notas
    → Estudiantes: lista, agregar, tap → notas individuales
    → AppBar: icono resumen → estadísticas de materia
    → Boletín: desde notas estudiante
```

## Plan de construcción
El plan completo está en `docs/PLAN.md` con 7 fases.
- Fase 1: Bugs ✅
- Fase 2: Materias subcolección ✅
- Fase 3: Evaluaciones subcolección ✅
- Fase 4: Estudiantes subcolección ✅
- Fase 5: Notas ✅
- Fase 6: Boletín y reportes ✅
- Fase 7: UX y pulido ✅ (parcial: falta pull-to-refresh, breadcrumbs, offline)

Para ejecutar la siguiente fase pendiente usa el comando `/build-phase`.

## Archivos de referencia
- `docs/PLAN.md` → Plan detallado de construcción (7 fases)
- `firestore.rules` → Reglas de seguridad de Firestore
