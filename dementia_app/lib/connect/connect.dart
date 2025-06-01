import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:mytestapp/main.dart';
import 'dart:ui';

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
                  String displayName = user.displayName ?? 'Unknown User';
                  String? photoURL = user.photoURL;

                  final theme = Theme.of(context);
                  final textTheme = theme.textTheme;
                  final textColor = theme.colorScheme.onSurface;
                  final colorScheme = theme.colorScheme;

                  return Scaffold(
                    extendBodyBehindAppBar: true,
                    drawer: Drawer(
                      elevation: 16.0,
                      child: Container(
                        color: colorScheme.onSurface,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            UserAccountsDrawerHeader(
                              accountName: Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              accountEmail: Text(
                                user.email ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              currentAccountPicture: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: photoURL != null
                                      ? NetworkImage(photoURL)
                                      : const AssetImage('assets/default.png')
                                          as ImageProvider,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF16213E),
                                    Color(0xFF0F3460)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            _buildDrawerItem(
                              icon: Icons.dashboard_rounded,
                              title: 'Dashboard',
                              onTap: () => Navigator.of(context)
                                  .pop(), // Fixed context usage
                            ),
                            _buildDrawerItem(
                              icon: Icons.trending_up_rounded,
                              title: 'Analytics',
                              onTap: () {},
                            ),
                            _buildDrawerItem(
                              icon: Icons.notifications_rounded,
                              title: 'Notifications',
                              onTap: () {},
                            ),
                            _buildDrawerItem(
                              icon: Icons.settings_rounded,
                              title: 'Settings',
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white24),
                            _buildDrawerItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Support',
                              onTap: () {},
                            ),
                            _buildDrawerItem(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(context, '/');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    appBar: AppBar(
                      title: const Text(
                        "Welcome",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      backgroundColor: colorScheme.surface,
                      elevation: 0,
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search_rounded),
                          onPressed: () {},
                          iconSize: 26,
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded),
                          onPressed: () {},
                          iconSize: 26,
                        ),
                      ],
                    ),
                    
      body:  Container(
                      decoration:  BoxDecoration(
                        //gradient: LinearGradient(
                          color: colorScheme.surface,
                            
                          
                         // stops: const [0.3, 0.7, 0.9],
                          //begin: Alignment.topCenter,
                          //end: Alignment.bottomRight,
                        //),
                      ),
                      child: SafeArea(
                        top: true,
                        child: ListView(
                          padding: const EdgeInsets.only(
                              top: 10, left: 20, right: 20, bottom: 20),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // User Profile Card
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Hero(
                                tag: 'role-badge',
                                child: Material(
                                  color: colorScheme.surface,
                                  child: Container(
                                    height: 140,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(                    
                                      color: colorScheme.surface,
                                      /*gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),*/
                                      borderRadius: BorderRadius.circular(20),
                                      //border: Border.all(color: Colors.white24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.onSurface.withOpacity(0.2),
                                          blurRadius: 8,
                                          //offset: const Offset(0, 8),
                                        )
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Profile Image
                                        Container(
                                          width: 75,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                            image: photoURL != null
                                                ? DecorationImage(
                                                    image:
                                                        NetworkImage(photoURL),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const DecorationImage(
                                                    image: AssetImage(
                                                        'assets/default.png'),
                                                    fit: BoxFit.cover,
                                                  ),
                                            boxShadow: [
                                             /* BoxShadow(
                                                color: colorScheme.surface,
                                                blurRadius: 5,
                                                offset: const Offset(0, 4),
                                              ),*/
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // User Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color:colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.tertiary.withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: colorScheme.tertiary                                               ,
                                                  ),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.tertiary
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon:Icon(
                                            Icons.edit_rounded,
                                            color: colorScheme.onSurface,
                                          ),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Section Title
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                             Padding(
                              padding: EdgeInsets.only(left: 5, bottom: 15),
                              child: Text(
                                "Quick Access",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:colorScheme.onSurface,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),

                            // Navigation Buttons Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              children: [
                                _buildFeatureButton(
                                  context,
                                  label: 'Games',
                                  description: 'Play brain games',
                                  textColor: colorScheme.surface,
                                  icon: Icons.sports_esports_rounded,
                                  /*gradientStart: const Color(0xFF4776E6),
                                  gradientEnd: const Color(0xFF8E54E9),*/
                                  color: colorScheme.tertiary,
                                  route: '/puzzles',
                                  tag: 'btn1',
                                ),
                                _buildFeatureButton(
                                  context,
                                  label: 'Medical Info',
                                  description: 'Track your health',
                                  textColor: colorScheme.onSurface,
                                  icon: Icons.medical_services_rounded,
                                  color: colorScheme.primary,
                                  route: '/medicineInfo',
                                  tag: 'btn2',
                                ),
                                _buildFeatureButton(
                                  context,
                                  label: 'Memory Aid',
                                  description: 'Remember important things',
                                  textColor: colorScheme.onSurface,
                                  icon: Icons.psychology_rounded,
                                  color: colorScheme.primary,
                                  route: '/memoryAid',
                                  tag: 'btn3',
                                ),
                                _buildFeatureButton(
                                  context,
                                  label: 'Community',
                                  description: 'Connect with others',
                                  textColor: colorScheme.surface,
                                  icon: Icons.alarm,
                                  color: colorScheme.tertiary,
                                  route: '/medicine',
                                  tag: 'btn4',
                                ),
                              ],
                            ),
                          ],
                        ),
                          ]
                      ),
                    ),
                  ),
  
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: () {
                        showNotification(
                          title: "New Message!",
                          body: "Caregiver sent you a new text",
                        );
                        Navigator.pushNamed(context, '/message');
                      },
                      
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.tertiary,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)
                      ),
                      icon: const Icon(Icons.volunteer_activism_rounded),
                      label: const Text(
                        "Chatbot",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white70,
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFeatureButton(
    BuildContext context, {
    required String label,
    required String description,
    required IconData icon,
    //required Color gradientStart,
    //required Color gradientEnd,
    required String route,
    required String tag,
    required Color color,
    required Color textColor,
    
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color,
              /*gradient: LinearGradient(
                colors: [gradientStart, gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),*/
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  //offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: textColor,
                    size: 32,
                  ),
                ),
                //const Spacer(),
                const SizedBox(height: 10),
                Text(
                  label,
                  style:  TextStyle(
                    color: textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
