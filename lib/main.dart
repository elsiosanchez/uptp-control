import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/seccion_provider.dart';
import 'providers/materia_provider.dart';
import 'providers/evaluacion_provider.dart';
import 'providers/estudiante_provider.dart';
import 'providers/nota_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UptpControlApp());
}

class UptpControlApp extends StatelessWidget {
  const UptpControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SeccionProvider()),
        ChangeNotifierProvider(create: (_) => MateriaProvider()),
        ChangeNotifierProvider(create: (_) => EvaluacionProvider()),
        ChangeNotifierProvider(create: (_) => EstudianteProvider()),
        ChangeNotifierProvider(create: (_) => NotaProvider()),
      ],
      child: MaterialApp(
        title: 'UPTP Control',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}
