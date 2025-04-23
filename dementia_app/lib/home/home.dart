import 'package:flutter/material.dart';
import 'package:mytestapp/login/login.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:mytestapp/role/role.dart';
import 'package:mytestapp/connect/connect.dart'; // Assuming this is your ConnectScreen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import User type

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Widget> _getInitialScreen(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null && doc.data()!['role'] != null) {
      return const ConnectScreen();
    } else {
      return const RoleScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("An error occurred"));
        } else if (snapshot.hasData) {
          final user = snapshot.data! as User; // Cast to User
          return FutureBuilder(
            future: _getInitialScreen(user.uid),
            builder: (context, AsyncSnapshot<Widget> futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (futureSnapshot.hasError) {
                return const Center(child: Text("Failed to load role"));
              } else {
                return futureSnapshot.data!;
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}