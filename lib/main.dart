import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/login_view.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Captura erros Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Captura erros em zonas não Flutter (async)
  runZonedGuarded(() async {
    try {
      await Firebase.initializeApp();
      runApp(const MyApp());
    } catch (e, stack) {
      print('Erro ao iniciar o app: $e');
      print(stack);
    }
  }, (error, stack) {
    print('Erro não capturado: $error');
    print(stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manteigaria Lisboa',
      debugShowCheckedModeBanner: false, // remove o banner de debug
      theme: ThemeData(primarySwatch: Colors.pink),
      home: LoginPage(),
    );
  }
}
