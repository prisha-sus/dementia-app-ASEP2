import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:mytestapp/main.dart'; // This should contain your showNotification function

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  Future<String?> getUserRole(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['role'] ?? 'No Role';
      } else {
        return 'No Role';
      }
    } catch (e) {
      print('Error fetching user role: $e');
      return 'No Role';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
              child: Text("Error occurred while fetching user data."));
        } else if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null && user.uid.isNotEmpty) {
            return FutureBuilder<String?>(
              future: getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roleSnapshot.hasError) {
                  return const Center(child: Text("Failed to load role"));
                } else {
                  String role = roleSnapshot.data ?? 'No Role';
                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    appBar: AppBar(
                      title: const Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Roboto',
                          letterSpacing: 1.2,
                        ),
                      ),
                      backgroundColor: const Color.fromARGB(117, 0, 0, 0),
                      elevation: 1,
                    ),
                    body: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 150),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'role-badge',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      'Role: $role',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              _buildNavButton(
                                context,
                                label: 'Games',
                                color: Colors.blueAccent,
                                route: '/quizzes',
                                tag: 'btn1',
                              ),
                              const SizedBox(height: 20),
                              _buildNavButton(
                                context,
                                label: 'Medical Information',
                                color: Colors.greenAccent.shade700,
                                route: '/medicineInfo',
                                tag: 'btn2',
                              ),
                              const SizedBox(height: 20),
                              _buildNavButton(
                                context,
                                label: 'Memory Aid',
                                color: Colors.deepOrange,
                                route: '/memoryAid',
                                tag: 'btn3',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Hero widget removed from here
                    floatingActionButton: FloatingActionButton(
                      onPressed: () {
                        showNotification(
                          title: "New Message!",
                          body: "Caregiver sent you a new text",
                        );
                        Navigator.pushNamed(context, '/message');
                      },
                      child: const Icon(Icons.message),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      elevation: 10,
                    ),
                    bottomNavigationBar: const BottomNavBar(),
                  );
                }
              },
            );
          } else {
            return const Center(child: Text("User data is missing."));
          }
        } else {
          return const Center(child: Text("No user found. Please login."));
        }
      },
    );
  }

  Widget _buildNavButton(BuildContext context,
      {required String label,
      required Color color,
      required String route,
      required String tag}) {
    return Hero(
      tag: tag,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          shadowColor: Colors.black45,
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
    );
  }
}
