import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
import 'package:mytestapp/main.dart'; // Needed for showNotification()

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text("I will add here a Boxtype UI which will take to each function"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showNotification(
            title: "👋 Hello!",
            body: "This is a local push notification.",
          );
        },
        child: const Icon(Icons.notifications),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
