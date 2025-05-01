import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mytestapp/routes.dart';
import 'package:mytestapp/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

bool isFirebaseInitialized = false; // Flag to track Firebase initialization
bool isFirstInit = true; // Flag to handle first initialization
Map<String, bool> initializedListeners =
    {}; // Track initialized listeners by publicId

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Check if Firebase is already initialized to avoid duplicate initialization
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp();
  }
  print('🔙 Background message: ${message.messageId}');
  print('🔙 Background message data: ${message.data}');
  print(
      '🔙 Background message notification: ${message.notification?.title}, ${message.notification?.body}');

  showNotification(
    title: message.notification?.title ?? "No Title",
    body: message.notification?.body ?? "No Body",
  );
}

Future<void> sendDangerAlert() async {
  const backendURL = 'http://192.168.2.125:3000';
  try {
    final mailRes = await http.post(
      Uri.parse('$backendURL/send_mail'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subject': 'Danger Alert',
        'text': 'Check on the patient immediately!',
      }),
    );
    final whatsappRes = await http.post(
      Uri.parse('$backendURL/send_whatsapp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': 'DANGER ALERT: Please check on the patient NOW!',
      }),
    );
    print('📧 Mail Status: ${mailRes.statusCode}');
    print('📱 WhatsApp Status: ${whatsappRes.statusCode}');
  } catch (e) {
    print('🚨 Error sending alert: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
    print('✅ Firebase initialized');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _requestNotificationPermission();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    print('✅ Flutter local notifications initialized');

    // Set up FCM foreground message handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground message: ${message.notification?.title}');
      print('📬 Foreground message data: ${message.data}');
      showNotification(
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
      );
    });

    // Setup listeners for realtime logs
    setupRealLogsListeners();

    runApp(const App());
  } catch (e) {
    print('❌ Firebase init error: $e');
    runApp(const ErrorApp());
  }
}

void setupRealLogsListeners() async {
  try {
    // Get all users with publicIds from the users collection
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('publicId', isNull: false)
        .get();

    print(
        '📋 Setting up listeners for ${usersSnapshot.docs.length} users with publicIds');

    // Set up a listener for each user's publicId
    for (var userDoc in usersSnapshot.docs) {
      final publicId = userDoc.get('publicId');
      if (publicId != null && publicId.toString().isNotEmpty) {
        listenToRealLogsForPublicId(publicId.toString());
      }
    }

    // Listen for changes in the users collection to catch new publicIds
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((userSnapshot) async {
      if (!isFirebaseInitialized) return;

      // Handle first initialization
      if (isFirstInit) {
        isFirstInit = false;
        return;
      }

      for (var change in userSnapshot.docChanges) {
        if (change.type == DocumentChangeType.modified ||
            change.type == DocumentChangeType.added) {
          final publicId = change.doc.get('publicId');
          if (publicId != null && publicId.toString().isNotEmpty) {
            // Only set up a listener if one doesn't already exist
            if (initializedListeners[publicId] != true) {
              listenToRealLogsForPublicId(publicId.toString());
            }
          }
        }
      }
    });
  } catch (e) {
    print('❌ Error setting up listeners: $e');
  }
}

void listenToRealLogsForPublicId(String publicId) {
  // Skip if already listening to this publicId
  if (initializedListeners[publicId] == true) {
    print('⏭️ Already listening to logs for $publicId, skipping');
    return;
  }

  print('👂 Setting up listener for logs/$publicId/realLogs');

  // Mark this publicId as having an active listener
  initializedListeners[publicId] = true;

  // Get the most recent timestamp first
  FirebaseFirestore.instance
      .collection('logs')
      .doc(publicId)
      .collection('realLogs')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get()
      .then((snapshot) {
    Timestamp? lastTimestamp;
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data['timestamp'] is Timestamp) {
        lastTimestamp = data['timestamp'] as Timestamp;
        print(
            '📅 Last known timestamp for $publicId: ${lastTimestamp.toDate()}');
      }
    }

    // Now listen for new logs that are more recent than lastTimestamp
    FirebaseFirestore.instance
        .collection('logs')
        .doc(publicId)
        .collection('realLogs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((realLogsSnapshot) async {
      for (var change in realLogsSnapshot.docChanges) {
        // Only process added documents
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          // Safely get timestamp and ensure it's not null
          final timestampData = data['timestamp'];
          if (timestampData is! Timestamp) continue;

          // Skip if this log is older than or equal to our last processed timestamp
          // if (lastTimestamp != null) {
          //   // Both timestamps are now guaranteed to be non-null
          //   final currentTimestamp = timestampData;
          //   // Fix: Handle nullable previousTimestamp properly
          //   if (currentTimestamp.compareTo(lastTimestamp) <= 0) {
          //     print(
          //         '⏭️ Skipping old log from ${currentTimestamp.toDate()} for $publicId');
          //     continue;
          //   }
          // }

          // Update lastTimestamp to this new message's timestamp
          lastTimestamp = timestampData;

          // Process the new log
          final message = data['message']?.toString();
          if (message != null) {
            print(
                '📥 New real-time log for $publicId: $message (${timestampData.toDate()})');
            processLogForNotification(
                publicId, Map<String, dynamic>.from(data));
          }
        }
      }
    }, onError: (error) {
      print('❌ Error in realtime listener for $publicId: $error');
    });
  }).catchError((error) {
    print('❌ Error getting initial timestamp for $publicId: $error');
  });
}

void processLogForNotification(
    String publicId, Map<String, dynamic> logData) async {
  try {
    // Get user info using publicId
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('publicId', isEqualTo: publicId)
        .limit(1)
        .get();

    String patientName = 'Patient';
    if (userQuery.docs.isNotEmpty) {
      patientName = userQuery.docs.first.get('name') ?? 'Patient';
    }

    String message = logData['message']?.toString() ?? '';
    print('🔍 Processing log message: "$message" for $patientName');

    if (message.contains('Caution')) {
      String title = 'Caution: $patientName acting suspicious';
      String body = message;
      print("🔔 Caution alert for patient: $patientName");
      showNotification(title: title, body: body);
    } else if (message.contains('Danger')) {
      String title = 'Danger: $patientName needs immediate attention';
      String body = "Check on the patient immediately";
      print("⚠️ Danger alert for patient: $patientName");
      showNotification(title: title, body: body);
      sendDangerAlert();
    } else {
      print('📝 Log does not contain alert keywords: $message');
    }
  } catch (e) {
    print('❌ Error processing notification: $e');
    // Fallback notification
    if (logData['message']?.toString().contains('Caution') == true) {
      showNotification(
        title: 'Caution Alert',
        body: logData['message'] ?? 'No details available',
      );
    } else if (logData['message']?.toString().contains('Danger') == true) {
      showNotification(
        title: 'Danger Alert',
        body: "Check on the patient immediately",
      );
      sendDangerAlert();
    }
  }
}

void _requestNotificationPermission() async {
  NotificationSettings settings = await _firebaseMessaging.requestPermission();
  print('🔐 Notification permission: ${settings.authorizationStatus}');
}

void showNotification({required String title, required String body}) async {
  const androidDetails = AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    channelDescription: 'App Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    details,
  );
  print("📲 Notification shown: $title - $body");
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: appRoutes,
      theme: appTheme,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Firebase Init Error')),
      ),
    );
  }
}