import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mytestapp/routes.dart';
import 'package:mytestapp/theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
    runApp(const App());
  } catch (e) {
    print('Error during Firebase initialization in main(): $e');
    runApp(const ErrorApp());
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: appRoutes,
      theme: appTheme,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Firebase Init Error')),
      ),
    );
  }
}
