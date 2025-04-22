import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:mytestapp/connect/connect.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});
void setRole(String role, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Set role in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': role,
        }, SetOptions(merge: true));

        // If role allocation is successful, navigate to the next screen
        Navigator.pushNamed(context, '/connect');
      } catch (e) {
        // If there's an error, you can show a snackbar or a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.userInjured),
              label: const Text("I'm a Patient"),
              onPressed: () => setRole('patient',context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.userDoctor),
              label: const Text("I'm a Caregiver"),
              onPressed: () => setRole("caregiver",context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
