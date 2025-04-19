import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(
      title: Text("Welcome "),
      backgroundColor: Colors.blue,
    ),
    body:Center(
     child: Text("I will add here a Boxtype UI which will take to each function"),
    ),
    bottomNavigationBar: BottomNavBar(),
    );
  }
}

