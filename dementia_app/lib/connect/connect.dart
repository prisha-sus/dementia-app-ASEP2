import 'package:flutter/material.dart';
import 'package:mytestapp/shared/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mytestapp/services/auth.dart';
import 'package:mytestapp/main.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

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
    final local = AppLocalizations.of(context);
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error fetching user data')),
          );
        } else if (snapshot.hasData) {
          final user = snapshot.data;
          if (user != null && user.uid.isNotEmpty) {
            return FutureBuilder<String?>(
              future: getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (roleSnapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Failed to load role')),
                  );
                } else {
                  String role = roleSnapshot.data ?? 'No Role';
                  String displayName = user.displayName ?? 'Unknown User';
                  String? photoURL = user.photoURL;

                  final theme = Theme.of(context);
                  final colorScheme = theme.colorScheme;

                  return Scaffold(
                    backgroundColor: colorScheme.surface,
                    extendBodyBehindAppBar: true,
                    drawer: Drawer(
                      elevation: 16.0,
                      child: Container(
                        color: colorScheme.surface,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                              color: colorScheme.primary,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: colorScheme.onPrimary, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            spreadRadius: 2,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        backgroundImage: photoURL != null
                                            ? NetworkImage(photoURL)
                                            : const AssetImage('assets/default.png')
                                                as ImageProvider,
                                        backgroundColor: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  Text(
                                    user.email ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onPrimary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.dashboard_rounded,
                              title: local?.dashboard ?? 'Dashboard',
                              onTap: () => Navigator.of(context).pop(),
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.trending_up_rounded,
                              title: local?.analytics ?? 'Analytics',
                              onTap: () {
                                Navigator.pushNamed(context, '/analytics');
                              },
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.notifications_rounded,
                              title: local?.notifications ?? 'Notifications',
                              onTap: () {},
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.settings_rounded,
                              title: local?.settings ?? 'Settings',
                              onTap: () {},
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 50),
                            Divider(
                              color: colorScheme.onSurface.withOpacity(0.3),
                              thickness: 1,
                              indent: 20,
                              endIndent: 20,
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.help_outline_rounded,
                              title: local?.helpSupport ?? 'Help & Support',
                              onTap: () {},
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 20),
                            _buildDrawerItem(
                              icon: Icons.logout_rounded,
                              title: local?.logout ?? 'Logout',
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(context, '/');
                              },
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                    appBar: AppBar(
                      title: Text(
                        local?.welcome ?? 'Welcome',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      backgroundColor: colorScheme.surface.withOpacity(0.9),
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
                    body: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                      ),
                      child: SafeArea(
                        top: true,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                              top: 10, left: 20, right: 20, bottom: 20),
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Language Selector
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButton<Locale>(
                                  value: Localizations.localeOf(context),
                                  dropdownColor: colorScheme.surface,
                                  onChanged: (Locale? newLocale) {
                                    if (newLocale != null) {
                                      App.setLocale(context, newLocale);
                                    }
                                  },
                                  underline: const SizedBox(),
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: Locale('en'),
                                      child: Text('English'),
                                    ),
                                    DropdownMenuItem(
                                      value: Locale('hi'),
                                      child: Text('हिंदी'),
                                    ),
                                    DropdownMenuItem(
                                      value: Locale('mr'),
                                      child: Text('मराठी'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // User Profile Card
                              Hero(
                                tag: 'role-badge',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
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
                                                color: colorScheme.primary,
                                                width: 2),
                                            image: photoURL != null
                                                ? DecorationImage(
                                                    image: NetworkImage(photoURL),
                                                    fit: BoxFit.cover,
                                                  )
                                                : const DecorationImage(
                                                    image: AssetImage(
                                                        'assets/default.png'),
                                                    fit: BoxFit.cover,
                                                  ),
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
                                                  color: colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
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
                              const SizedBox(height: 30),

                              // Section Title
                              Padding(
                                padding: const EdgeInsets.only(left: 5, bottom: 15),
                                child: Text(
                                  local?.quickAccess ?? 'Quick Access',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
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
                                    label: local?.games ?? 'Games',
                                    description: local?.gamesDescription ?? 'Play games',
                                    textColor: colorScheme.onPrimary,
                                    icon: Icons.sports_esports_rounded,
                                    color: colorScheme.primary,
                                    route: '/puzzles',
                                    tag: 'btn1',
                                  ),
                                  _buildFeatureButton(
                                    context,
                                    label: local?.medicineReminders ?? 'Medicine',
                                    description: local?.medicineRemindersDescription ?? 
                                        'Remember your medicines!',
                                    textColor: colorScheme.onSecondary,
                                    icon: Icons.medical_services_rounded,
                                    color: colorScheme.secondary,
                                    route: '/medicine',
                                    tag: 'btn2',
                                  ),
                                  _buildFeatureButton(
                                    context,
                                    label: local?.memoryAid ?? 'Memory Aid',
                                    description: local?.memoryAidDescription ?? 
                                        'Memory assistance tools',
                                    textColor: colorScheme.onTertiary,
                                    icon: Icons.psychology_rounded,
                                    color: colorScheme.tertiary,
                                    route: '/memoryAid',
                                    tag: 'btn3',
                                  ),
                                  _buildFeatureButton(
                                    context,
                                    label: local?.chatbot ?? 'Chatbot',
                                    description: local?.chatbotDescription ?? 
                                        'Chat with AI assistant',
                                    textColor: colorScheme.onError,
                                    icon: Icons.volunteer_activism_rounded,
                                    color: colorScheme.error,
                                    route: '/message',
                                    tag: 'btn4',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 100), // Space for bottom nav
                            ],
                          ),
                        ),
                      ),
                    ),
                    bottomNavigationBar: const BottomNavBar(),
                  );
                }
              },
            );
          } else {
            return Scaffold(
              body: Center(child: Text(local?.userDataMissing ?? 'User data missing')),
            );
          }
        } else {
          return Scaffold(
            body: Center(child: Text(local?.noUserFound ?? 'No user found')),
          );
        }
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: colorScheme.onSurface,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          fontFamily: GoogleFonts.nunito().fontFamily,
        ),
        overflow: TextOverflow.ellipsis,
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
                const SizedBox(height: 10),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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