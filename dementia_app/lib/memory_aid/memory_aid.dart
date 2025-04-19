import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
class MemoryAidScreen extends StatelessWidget {
  const MemoryAidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Memory Aid"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}