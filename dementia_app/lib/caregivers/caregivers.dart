import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
class CaregiversScreen extends StatelessWidget {
  const CaregiversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Connect to caregivers"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}