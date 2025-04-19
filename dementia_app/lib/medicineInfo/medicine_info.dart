import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
class MedicineInfoScreen extends StatelessWidget {
  const MedicineInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Medicine Info"),
        
        
      ),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}