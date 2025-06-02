import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;  
    final colorScheme = theme.colorScheme;
    final local = Localizations.of(context, AppLocalizations);
    return BottomNavigationBar(
      backgroundColor: colorScheme.background,
      selectedItemColor: colorScheme.tertiary,
      unselectedItemColor: colorScheme.onBackground,
      items: [
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house, size: 20),
            label: local.home),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.microphone, size: 20), 
            label: local.voice),
        BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.circleUser, size: 20), 
            label: local.profile)
      ],
      //fixedColor: colorScheme.onSurface,
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
