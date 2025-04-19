import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
class PuzzleScreen extends StatelessWidget {
  const PuzzleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Puzzle Screen"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}