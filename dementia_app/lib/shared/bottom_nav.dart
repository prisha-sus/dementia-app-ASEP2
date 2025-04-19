import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.kitMedical, size: 20),
            label: 'Dispenser'),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.microphone, size: 20), label: 'Voice'),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.circleUser, size: 20), label: 'Profile')
      ],
      fixedColor: Colors.deepPurple[200],
      onTap: (int idx) {
        switch (idx) {
          case 0:
             Navigator.pushNamed(context, '/medicineInfo');
            break;
          case 1:
            Navigator.pushNamed(context, '/voice');
            break;
          case 2:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
    );
  }
}
