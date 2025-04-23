import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mytestapp/services/auth.dart';

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
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserRole();
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

      setState(() {
        connectedToPatient = query.docs.isNotEmpty;
      });
    }
  }

  String generateOTP() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> sendCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && role == 'patient') {
      generatedOTP = generateOTP();

      await FirebaseFirestore.instance.collection('otps').doc(user.uid).set({
        'otp': generatedOTP,
        'timestamp': FieldValue.serverTimestamp(),
        'patientId': user.uid,
        'verified': false,
      });

      final url = Uri.parse('http://192.168.2.125:3000/send_otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"otp": "$generatedOTP"}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response.statusCode == 200
                ? 'OTP sent to caregiver!'
                : 'Failed to send OTP to caregiver')),
      );
    }
  }

  Future<void> verifyCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && role == 'caregiver') {
      final otpEntered = _otpController.text.trim();

      final otpQuery = await FirebaseFirestore.instance
          .collection('otps')
          .where('otp', isEqualTo: otpEntered)
          .where('verified', isEqualTo: false)
          .limit(1)
          .get();

      if (otpQuery.docs.isNotEmpty) {
        final otpDoc = otpQuery.docs.first;
        await otpDoc.reference
            .update({'verified': true, 'caregiverId': user.uid});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to patient!')),
        );

        setState(() {
          connectedToPatient = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP')),
        );
      }
    }
  }

  Widget buildLogList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return Text("No recent logs found.");
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['title'] ?? 'Untitled Log',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(log['message'] ?? 'No message'),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        formatTimestamp(log['timestamp']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text("Logout"),
              ),
              const SizedBox(height: 20),
              role == 'patient'
                  ? ElevatedButton(
                      onPressed: sendCode,
                      child: Text("Connect to a caregiver"),
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: _otpController,
                          decoration: InputDecoration(
                            hintText: 'Enter patient OTP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: verifyCode,
                          child: Text("Connect to a patient"),
                        ),
                        const SizedBox(height: 20),
                        if (connectedToPatient) ...[
                          Text(
                            "Recent Patient Logs",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          buildLogList(),
                        ]
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
