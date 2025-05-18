import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  void setRole(String role, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Generate a public-facing ID
        final String publicId = _generatePublicId();

        // Set role, email, public ID, name, and photo URL in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': role,
          'publicId': publicId,
          'name': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
        }, SetOptions(merge: true));

        // Navigate to the connect screen
        Navigator.pushNamed(context, '/connect');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Function to generate a random public ID
  String _generatePublicId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

   // ...existing code...
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Your Role',
          style: TextStyle(
            color: colorScheme.tertiary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0, // Remove AppBar shadow for a clean divider
      ),
      body: Column(
        children: [
          // Line after AppBar
          Container(
            height: 3,
            color: colorScheme.tertiary,
            margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: ElevatedButton.icon(
                      icon: FaIcon(
                        FontAwesomeIcons.userInjured,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                      label: Text(
                        "I'm a Patient",
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      onPressed: () => setRole('patient', context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 260,
                    child: ElevatedButton.icon(
                      icon: FaIcon(
                        FontAwesomeIcons.userDoctor,
                        color: colorScheme.background,
                        size: 22,
                      ),
                      label: Text(
                        "I'm a Caregiver",
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      onPressed: () => setRole("caregiver", context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
// ...existing code...
  }
