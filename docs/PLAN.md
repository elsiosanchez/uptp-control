# Plan de Construcción - UPTP Control (v2 - Subcolecciones)

## FASE 1: Corregir Bugs Actuales
- [x] **1.1** Corregir bug de secciones que no se muestran después de crearlas (resuelto: sorting client-side)
- [x] **1.2** Verificar CRUD completo de secciones: Crear, Leer, Editar, Eliminar
- [x] **1.3** Verificar que la lista se refresca automáticamente después de cada operación
- [x] **1.4** Verificar manejo de errores (mostrar snackbar si falla la operación)

## FASE 2: Materias Dentro de Sección (subcolección)
- [x] **2.1** Actualizar modelo `MateriaModel` (nombre, codigo, docente, activo, timestamps)
- [x] **2.2** Actualizar servicio Firestore con métodos de subcolección para materias
- [x] **2.3** Actualizar `MateriaProvider` con carga por seccionId
- [x] **2.4** Actualizar `SeccionDetailScreen` con materias de subcolección
- [x] **2.5** Actualizar formulario de materia para contexto de subcolección
- [x] **2.6** Actualizar navegación y Home screen

## FASE 3: Evaluaciones Dentro de Materia (subcolección)
- [x] **3.1** Crear modelo `EvaluacionModel` (nombre, porcentaje, fecha, orden)
- [x] **3.2** Crear servicio Firestore para evaluaciones como subcolección
- [x] **3.3** Crear `EvaluacionProvider` con carga por seccionId + materiaId
- [x] **3.4** Crear pantalla DETALLE DE MATERIA con pestañas (`materia_detail_screen.dart`)
- [x] **3.5** Crear formulario para agregar/editar evaluación
- [x] **3.6** Mostrar advertencia visual de porcentaje total (100%)

## FASE 4: Estudiantes Dentro de Materia (subcolección)
- [x] **4.1** Crear modelo `EstudianteModel` para subcolección
- [x] **4.2** Crear servicio Firestore para estudiantes como subcolección
- [x] **4.3** Crear `EstudianteProvider` con carga por seccionId + materiaId
- [x] **4.4** Implementar pestaña "Estudiantes" en `materia_detail_screen.dart`
- [x] **4.5** Crear formulario para agregar/editar estudiante
- [x] **4.6** Navegación desde estudiante → pantalla de notas

## FASE 5: Sistema de Notas (subcolección)
- [x] **5.1** Crear modelo `NotaModel` para subcolección
- [x] **5.2** Crear servicio Firestore para notas como subcolección
- [x] **5.3** Crear `NotaProvider` con carga por seccionId + materiaId
- [x] **5.4** Crear pantalla NOTAS DEL ESTUDIANTE (`notas_estudiante_screen.dart`)
- [x] **5.5** Crear pantalla CARGA MASIVA DE NOTAS (`carga_masiva_screen.dart`)
- [x] **5.6** Validaciones y reglas de negocio (0-20, 100%, etc.)

## FASE 6: Boletín y Reportes
- [x] **6.1** Crear pantalla BOLETÍN POR ESTUDIANTE
- [x] **6.2** Crear pantalla RESUMEN POR MATERIA (estadísticas)
- [ ] **6.3** Exportar boletín (opcional PDF)

## FASE 7: Mejoras de UX y Pulido
- [x] **7.1** Indicadores de carga en todas las pantallas (shimmer)
- [x] **7.2** Confirmación antes de eliminar
- [x] **7.3** Búsqueda/filtro en listas (secciones)
- [ ] **7.4** Pull-to-refresh
- [x] **7.5** Manejo de errores descriptivos (SnackBar)
- [ ] **7.6** Breadcrumbs o back contextual
- [x] **7.7** Empty states con ilustración
- [ ] **7.8** Modo offline (cache Firestore)
- [x] **7.9** Reglas de seguridad Firestore para subcolecciones
