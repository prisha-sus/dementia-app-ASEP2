import 'package:flutter/material.dart';
import 'package:mytestapp/login/login.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:mytestapp/connect/connect.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: AuthService().userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          } else if (snapshot.hasError) {
            return const Center(
              child: Text("error"),
            );
          } else if (snapshot.hasData) {
            return const ConnectScreen();
          } else {
            return const LoginScreen();
          }
        });
  }
}
