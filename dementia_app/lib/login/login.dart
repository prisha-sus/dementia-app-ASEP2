import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mytestapp/services/auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 150,
                ),
                Flexible(
                  child: LoginButton(
                    text: "Continue as Guest",
                    icon: FontAwesomeIcons.userNinja,
                    color: Colors.deepPurple,
                    loginMethod: AuthService().anonLogin,
                  ),
                ),
                LoginButton(
                  text: "Sign in with Google",
                  icon: FontAwesomeIcons.google,
                  color: Colors.blue,
                  loginMethod: AuthService().googleLogin,
                ),
                LoginButton(
                  text: "Sign in with Apple",
                  icon: FontAwesomeIcons.apple,
                  color: Colors.black,
                  loginMethod: AuthService().appleLogin,
                ),
              ],
            )));
  }
}

class LoginButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final Function loginMethod;

  const LoginButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.loginMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(24),
          backgroundColor: color,
        ),
        onPressed: () => loginMethod(),
      ),
    );
  }
}
