import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final local = Localizations.of(context, AppLocalizations);
    return Scaffold(
        body: Container(
           color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.only(bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.end,
children: [
  Image.asset(
    'assets/logo.png',
    height: 150,
  ),
  const SizedBox(height: 50),
  Flexible(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 260, // Set your desired width here
          child: LoginButton(
            text: local.continueAsGuest,
            icon: FontAwesomeIcons.userNinja,
            color: colorScheme.tertiary,
            textColor: colorScheme.background,
            iconColor: colorScheme.background,
            loginMethod: AuthService().anonLogin,
          ),
        ),
      ],
    ),
  ),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 260,
        child: LoginButton(
          text: local.signInWithGoogle,
          icon: FontAwesomeIcons.google,
          color: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          iconColor: colorScheme.onPrimary,
          loginMethod: AuthService().googleLogin,
        ),
      ),
    ],
  ),
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 260,
        child: LoginButton(
          text: local.signInWithApple,
          icon: FontAwesomeIcons.apple,
          color: colorScheme.secondary,
          textColor: colorScheme.onSecondary,
          iconColor: colorScheme.onSecondary,
          loginMethod: AuthService().appleLogin,
        ),
      ),
    ],
  ),
],
            ),
          ),
        
        );
  }
}

class LoginButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Function loginMethod;
  final Color textColor;
  final Color iconColor;

  const LoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.loginMethod,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 50),
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
        label: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(22),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
        ),
        onPressed: () => loginMethod(),
      ),
    );
  }
}
