# Arquitectura - UPTP Control

## Capas de la Aplicación

```
┌─────────────────────────────────────────┐
│           PRESENTATION LAYER            │
│  Screens (UI) + Widgets reutilizables   │
│  Solo muestran datos y capturan input   │
├─────────────────────────────────────────┤
│          STATE MANAGEMENT               │
│  Providers (ChangeNotifier)             │
│  Exponen datos y acciones a la UI       │
│  Escuchan streams de Firestore          │
├─────────────────────────────────────────┤
│            DATA LAYER                   │
│  Services (Auth + Firestore)            │
│  CRUD contra Firebase                   │
│  Retornan Streams y Futures             │
├─────────────────────────────────────────┤
│             MODELS                      │
│  Clases Dart con fromFirestore/toMap    │
│  Representación de datos                │
├─────────────────────────────────────────┤
│         FIREBASE BACKEND                │
│  Auth │ Firestore │ Storage │ Functions │
└─────────────────────────────────────────┘
```

## Flujo de Datos

```
UI (Screen)
  ↓ llama acción
Provider (ChangeNotifier)
  ↓ delega a
Service (FirestoreService)
  ↓ escribe/lee
Firebase Firestore
  ↓ stream actualiza
Service → Provider → notifyListeners() → UI se reconstruye
```

## Dependencias (pubspec.yaml)
```yaml
firebase_core: ^3.8.0
firebase_auth: ^5.3.0
cloud_firestore: ^5.5.0
firebase_storage: ^12.3.0
provider: ^6.1.2
google_fonts: ^6.2.1
intl: ^0.19.0
uuid: ^4.5.1
```

## Navegación
Rutas nombradas definidas en `config/routes.dart`.
Flujo: Login → Home → [Secciones | Materias | Estudiantes | Notas]
Cada módulo tiene: Lista (screen) + Formulario (form) + Detalle (detail, si aplica)
