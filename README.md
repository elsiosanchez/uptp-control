# 📚 UPTP Control

Sistema de control de notas estudiantiles desarrollado con **Flutter** y **Firebase**, diseñado para gestionar secciones, materias, estudiantes y calificaciones de manera sencilla y eficiente.

---

## 📋 Descripción

**UPTP Control** es una aplicación móvil que permite a un usuario administrador llevar el control completo de notas de estudiantes organizados por sección y materia. Cada sección puede tener múltiples materias asignadas, y cada estudiante inscrito recibe sus calificaciones por evaluación.

---

## ✨ Funcionalidades

### 🏫 Gestionar Secciones
- Crear, editar y eliminar secciones
- Asignar turno (mañana, tarde, noche) y año escolar
- Visualizar las materias y estudiantes asociados a cada sección

### 📚 Gestionar Materias
- Registrar materias con código y horas semanales
- Asignar materias a cada sección de forma independiente
- Cada sección puede tener distintas materias

### 🎓 Gestionar Estudiantes
- Registrar estudiantes con sus datos personales (cédula, nombre, apellido)
- Inscribir estudiantes en una sección
- Consultar el historial de notas por estudiante

### 💯 Gestionar Notas
- Crear evaluaciones por materia (exámenes, tareas, quiz, proyectos)
- Registrar calificaciones individuales por estudiante y evaluación
- Asignar ponderación a cada evaluación
- Cálculo automático de promedios

---

## 🛠️ Tecnologías

| Tecnología | Uso |
|---|---|
| **Flutter** | Framework de desarrollo móvil |
| **Dart** | Lenguaje de programación |
| **Firebase Auth** | Autenticación de usuario |
| **Cloud Firestore** | Base de datos en la nube |
| **Provider** | Gestión de estado |

---

## 📁 Estructura del Proyecto

```
lib/
├── config/                  # Configuración general
│   ├── app_theme.dart       # Tema visual de la app
│   ├── constants.dart       # Constantes y colecciones
│   └── routes.dart          # Definición de rutas
├── models/                  # Modelos de datos
│   ├── usuario_model.dart
│   ├── seccion_model.dart
│   ├── materia_model.dart
│   ├── estudiante_model.dart
│   ├── evaluacion_model.dart
│   └── nota_model.dart
├── services/                # Servicios Firebase
│   ├── auth_service.dart
│   └── firestore_service.dart
├── providers/               # State Management
│   ├── auth_provider.dart
│   ├── seccion_provider.dart
│   ├── materia_provider.dart
│   ├── estudiante_provider.dart
│   └── nota_provider.dart
├── screens/                 # Pantallas
│   ├── auth/                # Login
│   ├── home/                # Dashboard principal
│   ├── secciones/           # CRUD Secciones
│   ├── materias/            # CRUD Materias
│   ├── estudiantes/         # CRUD Estudiantes
│   └── notas/               # Registro de notas
├── widgets/                 # Componentes reutilizables
└── main.dart                # Punto de entrada
```

---

## 🗄️ Modelo de Datos

```
secciones/           → Secciones académicas
materias/            → Catálogo de materias
seccion_materias/    → Relación sección ↔ materia
estudiantes/         → Registro de estudiantes
inscripciones/       → Estudiantes inscritos por sección
evaluaciones/        → Evaluaciones por materia
notas/               → Calificaciones por estudiante
```

### Relación entre entidades

```
Sección ──┬── tiene muchas ──→ Materias (via seccion_materias)
           └── tiene muchos ──→ Estudiantes (via inscripciones)

Materia ── tiene muchas ──→ Evaluaciones

Evaluación ── genera muchas ──→ Notas ←── pertenecen a ── Estudiante
```

---

## 🚀 Instalación

### Prerrequisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.2.0
- [Firebase CLI](https://firebase.google.com/docs/cli)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- Cuenta de [Firebase](https://console.firebase.google.com/)

### Configuración

```bash
# 1. Clonar el repositorio
git clone https://github.com/elsiosanchez/uptp-control.git
cd uptp-control

# 2. Configurar Firebase
firebase login
flutterfire configure

# 3. Instalar dependencias
flutter pub get

# 4. Ejecutar la aplicación
flutter run
```

### Configuración Android

En `android/app/build.gradle`, verificar que `minSdk` sea 21:

```gradle
defaultConfig {
    minSdk = 21
}
```

---

## 📱 Capturas de Pantalla

> _Próximamente_

---

## 👤 Autor

**Elsio Sánchez**
- GitHub: [@elsiosanchez](https://github.com/elsiosanchez)

---

## 📄 Licencia

Este proyecto es de uso educativo.
