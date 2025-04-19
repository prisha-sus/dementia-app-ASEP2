import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Voice Recognition"),
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}