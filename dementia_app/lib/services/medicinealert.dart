import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Reminder model
class MedicationReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final DateTime timeToTake;
  final bool isRecurring;
  final List<int> daysToRepeat;
  final int alarmDuration; // Duration in seconds the alarm should sound

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.timeToTake,
    this.isRecurring = false,
    this.daysToRepeat = const [],
    this.alarmDuration = 30, // Default to 30 seconds
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineName': medicineName,
        'dosage': dosage,
        'timeToTake': Timestamp.fromDate(timeToTake),
        'isRecurring': isRecurring,
        'daysToRepeat': daysToRepeat,
        'alarmDuration': alarmDuration,
        'createdAt': Timestamp.now(),
      };

  factory MedicationReminder.fromMap(Map<String, dynamic> map) =>
      MedicationReminder(
        id: map['id'],
        medicineName: map['medicineName'],
        dosage: map['dosage'],
        timeToTake: (map['timeToTake'] as Timestamp).toDate(),
        isRecurring: map['isRecurring'] ?? false,
        daysToRepeat: List<int>.from(map['daysToRepeat'] ?? []),
        alarmDuration: map['alarmDuration'] ?? 30,
      );

  // Serialize to JSON 
  String toJson() => json.encode(toMap());

  // Deserialize from JSON 
  factory MedicationReminder.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return MedicationReminder.fromMap(map);
  }
}

/// Reminder service
class MedicationReminderService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Channel IDs for different notification importance
  static const String _medicationChannelId = 'medication_reminders';
  static const String _medicationAlarmChannelId = 'medication_alarm';
  
  // For keeping track of currently playing alarm
  static String? _currentlyPlayingAlarmId;
  
  // Singleton instance
  static MedicationReminderService? _instance;
  
  // Flag to track initialization status
  bool _isInitialized = false;
  
  // Factory constructor for singleton pattern
  factory MedicationReminderService() {
    _instance ??= MedicationReminderService._internal();
    return _instance!;
  }
  
  // Private constructor
  MedicationReminderService._internal();
  
  // Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('Initializing MedicationReminderService...');
    await _initializeNotifications();
    tz_data.initializeTimeZones();
    _isInitialized = true;
    print('MedicationReminderService initialized successfully.');
  }

  Future<void> _initializeNotifications() async {
    print('Initializing notification plugin...');
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create notification channels with different importance levels
    await _createNotificationChannels();

    // Handle notification responses
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    print('Notification plugin initialized.');
  }
  
  void _handleNotificationResponse(NotificationResponse details) {
    // This will be called when the app receives a notification in the foreground
    print('Notification tapped: ${details.payload}');
    
    // Parse payload and stop alarm if it's running
    if (details.payload != null) {
      final payloadParts = details.payload!.split('|');
      if (payloadParts.isNotEmpty) {
        final reminderId = payloadParts[0];
        _stopAlarm(reminderId);
      }
    }
  }
  
  Future<void> _createNotificationChannels() async {
    // For standard reminders
    const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
      _medicationChannelId,
      'Medication Reminders',
      description: 'Notifications for medication reminders',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );
    
    // For alarm-style reminders (higher importance)
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      _medicationAlarmChannelId,
      'Medication Alarms',
      description: 'High priority medication alarms',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );
    
    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (plugin != null) {
      await plugin.createNotificationChannel(medicationChannel);
      await plugin.createNotificationChannel(alarmChannel);
      
      // Request exact alarm permission and notifications permission on Android
      await plugin.requestExactAlarmsPermission();
      await plugin.requestNotificationsPermission();
    }
  }
  
  // Play alarm directly in app
  Future<void> _playAlarm(MedicationReminder reminder) async {
    _currentlyPlayingAlarmId = reminder.id;
    try {
      final audioPlayer = AudioPlayer();
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('sounds/alarm_sound.mp3'), volume: 1.0);
      
      // Add vibration
      HapticFeedback.heavyImpact();
      
      // Show persistent notification
      await _showAlarmNotification(reminder);
      
      // Schedule alarm stop after specified duration
      Future.delayed(Duration(seconds: reminder.alarmDuration), () {
        _stopAlarm(reminder.id);
      });
    } catch (e) {
      print('Error playing alarm: $e');
    }
  }
  
  Future<void> _showAlarmNotification(MedicationReminder reminder) async {
    final androidDetails = AndroidNotificationDetails(
      _medicationAlarmChannelId,
      'Medication Alarms',
      channelDescription: 'High priority medication alarms',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
      color: const Color(0xFF2C5364),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.wav',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'medication_alarm',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create a payload with reminder information to be used when notification is tapped
    final payload = '${reminder.id}|${reminder.medicineName}|${reminder.dosage}';
    
    await _notificationsPlugin.show(
      reminder.id.hashCode,
      'Time to take ${reminder.medicineName}!',
      '${reminder.dosage} - Tap to stop alarm',
      notificationDetails,
      payload: payload,
    );
  }
  
  Future<void> _stopAlarm(String reminderId) async {
    if (_currentlyPlayingAlarmId == reminderId) {
      await _audioPlayer.stop();
      _currentlyPlayingAlarmId = null;
      
      // Cancel the persistent notification
      await _notificationsPlugin.cancel(reminderId.hashCode);
    }
  }

  Future<void> addMedicationReminder(MedicationReminder reminder) async {
    if (!_isInitialized) {
      print('Error: MedicationReminderService not initialized.');
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in.');
      return;
    }

    print('Adding reminder for user: ${user.uid}');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationReminders')
        .doc(reminder.id)
        .set(reminder.toMap());

    print('Reminder saved to Firestore: ${reminder.toMap()}');
    await _scheduleNotification(reminder);
  }

  Future<void> _scheduleNotification(MedicationReminder reminder) async {
    print('Scheduling notification for reminder: ${reminder.id}');
    
    final androidDetails = AndroidNotificationDetails(
      _medicationAlarmChannelId,
      'Medication Alarms',
      channelDescription: 'High priority medication alarms',
      importance: Importance.max,
      priority: Priority.max,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
      color: const Color(0xFF2C5364),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm_sound.wav',
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'medication_alarm',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create a payload with reminder information to be used when notification is tapped
    final payload = '${reminder.id}|${reminder.medicineName}|${reminder.dosage}';
    
    try {
      final scheduledTime = tz.TZDateTime.from(reminder.timeToTake, tz.local);
      print('Scheduled time: $scheduledTime');
  
      if (reminder.isRecurring) {
        print('Setting up recurring notifications...');
        for (final day in reminder.daysToRepeat) {
          final nextDay = _nextInstanceOfDay(day, reminder.timeToTake);
          print('Next instance for weekday $day: $nextDay');
          await _notificationsPlugin.zonedSchedule(
            reminder.id.hashCode + day,
            'Time to take ${reminder.medicineName}!',
            '${reminder.dosage} - Tap to stop alarm',
            nextDay,
            notificationDetails,
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      } else {
        print('Setting one-time notification...');
        await _notificationsPlugin.zonedSchedule(
          reminder.id.hashCode,
          'Time to take ${reminder.medicineName}!',
          '${reminder.dosage} - Tap to stop alarm',
          scheduledTime,
          notificationDetails,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      }
      
      // Schedule alarm and notification for this reminder
      Future.delayed(scheduledTime.difference(DateTime.now()), () {
        _playAlarm(reminder);
      });
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int weekday, DateTime baseTime) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, baseTime.hour, baseTime.minute);

    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  Future<List<MedicationReminder>> getMedicationReminders() async {
    if (!_isInitialized) {
      print('Error: MedicationReminderService not initialized.');
      return [];
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in.');
      return [];
    }

    print('Fetching reminders for user: ${user.uid}');
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationReminders')
        .orderBy('timeToTake')
        .get();

    final reminders =
        snapshot.docs.map((doc) => MedicationReminder.fromMap(doc.data())).toList();
    print('Fetched ${reminders.length} reminders.');
    return reminders;
  }

  Future<void> deleteMedicationReminder(String reminderId) async {
    if (!_isInitialized) {
      print('Error: MedicationReminderService not initialized.');
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in.');
      return;
    }

    print('Deleting reminder: $reminderId');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationReminders')
        .doc(reminderId)
        .delete();

    // Cancel notification
    await _notificationsPlugin.cancel(reminderId.hashCode);
    
    // Stop alarm if it's playing
    _stopAlarm(reminderId);
    
    print('Reminder and its notification cancelled.');
  }

  Future<void> updateMedicationReminder(MedicationReminder reminder) async {
    if (!_isInitialized) {
      print('Error: MedicationReminderService not initialized.');
      return;
    }
    
    print('Updating reminder: ${reminder.id}');
    await deleteMedicationReminder(reminder.id);
    await addMedicationReminder(reminder);
  }

  /// Stops all currently playing alarms and notifications
  Future<void> stopAllAlarms() async {
    if (_currentlyPlayingAlarmId != null) {
      await _stopAlarm(_currentlyPlayingAlarmId!);
    }
    await _notificationsPlugin.cancelAll();
  }

  /// Clears all medication reminders for the current user
  Future<void> clearAllReminders() async {
    if (!_isInitialized) {
      print('Error: MedicationReminderService not initialized.');
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      print('No user logged in.');
      return;
    }

    // Stop all current alarms
    await stopAllAlarms();

    // Delete all reminders from Firestore
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicationReminders')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    print('All medication reminders cleared.');
  }
}