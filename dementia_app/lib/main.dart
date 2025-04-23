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
bool isFirstInit = true; // Flag to ensure we don't send notifications for existing logs

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔙 Background message: ${message.messageId}');
  // Log the data payload and notification content
  print('🔙 Background message data: ${message.data}');
  print(
      '🔙 Background message notification: ${message.notification?.title}, ${message.notification?.body}');
  
  // Show notification here when the app is in background
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
    isFirebaseInitialized = true; // Set the flag to true when Firebase is initialized
    print('✅ Firebase initialized');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _requestNotificationPermission();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    print('✅ Flutter local notifications initialized');

    // Now start listening to Firestore changes only after Firebase initialization
    if (isFirebaseInitialized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📬 Foreground message: ${message.notification?.title}');
        print('📬 Foreground message data: ${message.data}');
        showNotification(
          title: message.notification?.title ?? "No Title",
          body: message.notification?.body ?? "No Body",
        );
      });

      // Listen for changes in Firestore logs collection
      FirebaseFirestore.instance
          .collection('logs')
          .snapshots()
          .listen((snapshot) {
        if (!isFirebaseInitialized) return; // Ensure this block doesn't execute before initialization
        if (isFirstInit) {
          // Skip processing existing documents on first initialization
          isFirstInit = false;
          return;
        }

        print("🔄 Listening to Firestore logs collection...");
        for (var doc in snapshot.docChanges) {
          print("🔄 Processing document change: ${doc.doc.id}");
          if (doc.type == DocumentChangeType.added) {
            print("✅ New document added to logs collection: ${doc.doc.id}");
            var data = doc.doc.data();
            if (data != null && data['message'].contains('Caution')) {
              String title = 'Caution';
              String body = data['message'] ?? 'No Body';
              print("🔔 Caution found in new document");
              print('📬 New Log with Caution: $title - $body');
              showNotification(title: title, body: body);
            } else if (data != null && data['message'].contains('Danger:')) {
              String title = 'Danger';
              String body = "Check on the patient immediately";
              print("Danger message send");
              showNotification(title: title, body: body);
              sendDangerAlert();
            }
          } else if (doc.type == DocumentChangeType.modified) {
            print("⚡ Document modified: ${doc.doc.id}");
            var data = doc.doc.data();
            print("Modified Data: $data");
          } else if (doc.type == DocumentChangeType.removed) {
            print("❌ Document removed: ${doc.doc.id}");
          }
        }
      });
    }

    runApp(const App());
  } catch (e) {
    print('❌ Firebase init error: $e');
    runApp(const ErrorApp());
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