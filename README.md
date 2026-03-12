# UPTP Control

App movil Flutter + Firebase para control de notas estudiantiles. Un solo usuario administrador gestiona secciones, materias, estudiantes y calificaciones.

## Requisitos previos

Antes de comenzar, asegurate de tener instalado:

- **Flutter SDK** >= 3.19.x ([Guia de instalacion](https://docs.flutter.dev/get-started/install))
- **Dart SDK** >= 3.3.x (incluido con Flutter)
- **Android Studio** o **VS Code** con extensiones de Flutter/Dart
- **Git**
- **Cuenta de Firebase** con un proyecto creado
- **Node.js** >= 18 (para Firebase CLI)

Verifica tu instalacion:

```bash
flutter doctor
```

## Paso 1: Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd uptp-control
```

## Paso 2: Instalar dependencias de Flutter

```bash
flutter pub get
```

## Paso 3: Configurar Firebase

### 3.1 Instalar Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 3.2 Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 3.3 Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto (ej: `uptp-control`)
3. Habilita **Authentication** con el proveedor Email/Password
4. Habilita **Cloud Firestore** en modo de prueba o produccion

### 3.4 Conectar Firebase con el proyecto Flutter

Desde la raiz del proyecto ejecuta:

```bash
flutterfire configure --project=<tu-proyecto-firebase>
```

Esto genera automaticamente los archivos de configuracion:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist` (si aplica)

### 3.5 Habilitar Firebase en el codigo

En `lib/main.dart`, descomenta las lineas de Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UptpControlApp());
}
```

### 3.6 Publicar reglas de Firestore

```bash
firebase deploy --only firestore:rules
```

## Paso 4: Crear usuario administrador

1. Ve a Firebase Console > Authentication > Users
2. Agrega un usuario con email y contrasena
3. En Firestore, crea un documento en la coleccion `users` con el `uid` del usuario:

```
users/{uid}
  nombre: "Administrador"
  email: "tu@email.com"
  rol: "admin"
  activo: true
  created_at: <timestamp>
```

## Paso 5: Ejecutar la aplicacion

### En emulador Android

```bash
flutter run
```

### En Chrome (web)

```bash
flutter run -d chrome
```

### En dispositivo fisico

1. Conecta tu dispositivo Android por USB
2. Habilita **Depuracion USB** en opciones de desarrollador
3. Ejecuta:

```bash
flutter devices          # Verifica que detecta tu dispositivo
flutter run -d <device>  # Ejecuta en el dispositivo
```

## Paso 6: Build de release

### APK (Android)

```bash
flutter build apk
```

El APK se genera en: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Google Play)

```bash
flutter build appbundle
```

## Comandos utiles

| Comando | Descripcion |
|---------|-------------|
| `flutter pub get` | Instalar dependencias |
| `flutter run` | Ejecutar en dispositivo/emulador |
| `flutter run -d chrome` | Ejecutar en web |
| `flutter analyze` | Analisis estatico del codigo |
| `flutter test` | Ejecutar tests |
| `flutter build apk` | Build de release Android |
| `flutterfire configure` | Reconfigurar Firebase |

## Estructura del proyecto

```
lib/
├── config/          # Tema, constantes y rutas
├── models/          # Modelos de datos (fromFirestore/toMap)
├── services/        # Servicios de Auth y Firestore
├── providers/       # State management (ChangeNotifier)
├── screens/         # Pantallas por modulo
│   ├── auth/        # Login
│   ├── home/        # Dashboard
│   ├── secciones/   # CRUD secciones + detalle
│   ├── materias/    # CRUD materias
│   ├── estudiantes/ # CRUD estudiantes + inscripciones
│   ├── evaluaciones/# CRUD evaluaciones
│   └── notas/       # Registro de notas + boletin
├── widgets/         # Componentes reutilizables
└── main.dart        # Entry point
```

## Stack tecnologico

- **Framework:** Flutter 3.x con Dart
- **Backend:** Firebase (Auth, Cloud Firestore)
- **State Management:** Provider (ChangeNotifier)
- **UI:** Material 3 con Google Fonts

## Solucion de problemas

### Error de version de Kotlin

Si ves errores de version de Kotlin al compilar, actualiza la version en `android/build.gradle`:

```gradle
ext.kotlin_version = '1.8.20'
```

### Error "No Firebase App"

Asegurate de haber ejecutado `flutterfire configure` y descomentado `Firebase.initializeApp()` en `main.dart`.

### minSdk demasiado bajo

El proyecto requiere `minSdkVersion 21`. Esto ya esta configurado en `android/app/build.gradle`.
