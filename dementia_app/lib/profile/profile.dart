import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mytestapp/services/auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

String formatTimestamp(dynamic ts) {
  if (ts is Timestamp) {
    return ts.toDate().toLocal().toString().split('.').first;
  } else if (ts is int) {
    return DateTime.fromMillisecondsSinceEpoch(ts)
        .toLocal()
        .toString()
        .split('.')
        .first;
  } else {
    return 'Unknown time';
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? role;
  String? generatedOTP;
  bool connectedToPatient = false;
  String? linkedPatientId;
  String? linkedPatientName; // Add this line
  final TextEditingController _otpController = TextEditingController();

  String generateOTP() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  void initState() {
    super.initState();
    getUserRole();
    getUserName();
  }

  String userName = "User";

  Future<void> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.get('name') ?? "User";
        });
      }
    }
  }

  Future<void> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          role = doc['role'];
        });
        if (doc['role'] == 'caregiver') {
          checkIfConnected();
        }
      }
    }
  }

  Future<void> checkIfConnected() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('otps')
          .where('caregiverId', isEqualTo: user.uid)
          .where('verified', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          connectedToPatient = true;
        });

        final patientId = query.docs.first.get('patientId');
        final patientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .get();

        if (patientDoc.exists) {
          setState(() {
            linkedPatientId = patientDoc.get('publicId');
            linkedPatientName = patientDoc.get('name');
          });
        }
      }
    }
  }

  Widget buildLogList() {
    final colorScheme = Theme.of(context).colorScheme;
    final local = Localizations.of(context, AppLocalizations)!;
    if (role == 'caregiver' && linkedPatientId == null) {
      return  Center(
        child: Text(
          local.noPatientConnected,
          style: TextStyle(color: colorScheme.onPrimary),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .doc(linkedPatientId ?? FirebaseAuth.instance.currentUser?.uid)
          .collection('realLogs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  Center(
            child: CircularProgressIndicator(color: colorScheme.onPrimary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              local.noLogsAvailable,
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          );
        }

        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 48, color: colorScheme.onPrimary),
                const SizedBox(height: 16),
                 Text(
                  local.noActivitiesLoggedYet,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.background,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  log['message'] ?? 'No details available',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                    height: 1.4,
                  ),
                ),
                trailing: Text(
                  formatTimestamp(log['timestamp']),
                  style:  TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Add this new widget for the activity summary
  Widget _buildActivitySummary() {
    final local = Localizations.of(context, AppLocalizations)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            local.gamesPlayed,
            "12",
            Icons.sports_esports_rounded,
            colorScheme.primary,
            colorScheme.onPrimary,
            colorScheme.onPrimary
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            local.memoryNotes,
            "8",
            Icons.note_alt_rounded,
            colorScheme.tertiary,
            colorScheme.background,
            colorScheme.background,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, Color textColor, Color iconColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final local = Localizations.of(context, AppLocalizations)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(height: 12),
          Text(
            value,
            style:  TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendCode() async {
    setState(() {
      generatedOTP = generateOTP();
    });
final local = Localizations.of(context, AppLocalizations)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && role == 'patient') {
      try {
        await FirebaseFirestore.instance.collection('otps').doc(user.uid).set({
          'otp': generatedOTP,
          'timestamp': FieldValue.serverTimestamp(),
          'patientId': user.uid,
          'verified': false,
        });

        final url = Uri.parse('http://192.168.27.125:3000/send_otp');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: '{"otp": "$generatedOTP"}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.statusCode == 200
                ? local.otpSentToCaregiver
                : local.failedToSendOTP),
            backgroundColor:
                response.statusCode == 200 ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> verifyCode() async {
    final user = FirebaseAuth.instance.currentUser;
    final otpEntered = _otpController.text.trim();
    final local = Localizations.of(context, AppLocalizations)!;

    if (user != null && role == 'caregiver' && otpEntered.isNotEmpty) {
      try {
        final otpQuery = await FirebaseFirestore.instance
            .collection('otps')
            .where('otp', isEqualTo: otpEntered)
            .where('verified', isEqualTo: false)
            .limit(1)
            .get();

        if (otpQuery.docs.isNotEmpty) {
          final otpDoc = otpQuery.docs.first;
          final patientId = otpDoc.get('patientId');

          // Fetch patient info
          final patientDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

          await otpDoc.reference.update({
            'verified': true,
            'caregiverId': user.uid,
            'verifiedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            connectedToPatient = true;
            linkedPatientName = patientDoc.get('name');
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${local.connectedTo} $linkedPatientName ${local.successfully}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _otpController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text(local.invalidCode),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${local.error} $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = Localizations.of(context, AppLocalizations)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      extendBodyBehindAppBar: true, // Added this
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.background,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: colorScheme.background),
          ),
        ),
        title:  Text(
          local.myProfile,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:  Icon(Icons.logout_rounded, color: colorScheme.onPrimary),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            tooltip: local.logout,
          ),
        ],
      ),
      body: Container(
        decoration:  BoxDecoration(
          color: colorScheme.background,
          /*gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),*/
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(), // Added this
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.onPrimary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(1, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.background, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.onPrimary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundImage: FirebaseAuth
                                      .instance.currentUser?.photoURL !=
                                  null
                              ? NetworkImage(
                                  FirebaseAuth.instance.currentUser!.photoURL!)
                              : const AssetImage('assets/default.png')
                                  as ImageProvider,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              role == 'patient' ? local.patient : local.caregiver,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimary.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? "",
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onPrimary.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                _buildActivitySummary(),
                SizedBox(height: 24),
                if (role == 'patient') ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.background,
                      /*gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),*/
                      borderRadius: BorderRadius.circular(20),
                      //border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local.connectWithCaregiver,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          local.shareCodeWithCaregiver,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: sendCode,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(double.infinity, 0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.connect_without_contact),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  local.generateCodeConnection,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (generatedOTP != null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.tertiary.withOpacity(0.2)!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color:colorScheme.tertiary, size: 32),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        local.yourCodeIs,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.tertiary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        generatedOTP!,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.tertiary,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        local.shareThisCodeWithCaregiver,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.background,
                      /*gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),*/
                      borderRadius: BorderRadius.circular(20),
                      //border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local.connectWithPatient,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          local.enterCodeFromPatient,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            hintText: local.enterPatientCode,
                            hintStyle: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.vpn_key_outlined,
                                color: colorScheme.primary),
                            filled: true,
                            fillColor: colorScheme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          style:  TextStyle(
                            fontSize: 18,
                            letterSpacing: 1.5,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: verifyCode,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.background,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size(double.infinity, 0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text(
                                local.verifyCode,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (role == 'caregiver') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.background,
                      /*gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),*/
                      borderRadius: BorderRadius.circular(20),
                      //border: Border.all(color: colorScheme.onPrimary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(1, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          local.patientActivity,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        buildLogList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
