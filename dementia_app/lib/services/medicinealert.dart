import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Reminder model
class MedicationReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final DateTime timeToTake;
  final bool isRecurring;
  final List<int> daysToRepeat;
  final int alarmDuration;

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.timeToTake,
    this.isRecurring = false,
    this.daysToRepeat = const [],
    this.alarmDuration = 30,
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

  String toJson() => json.encode(toMap());

  factory MedicationReminder.fromJson(String jsonString) {
    final Map<String, dynamic> map = json.decode(jsonString);
    return MedicationReminder.fromMap(map);
  }
}

/// Reminder service
class MedicationReminderService {
  final _logger = Logger('MedicationReminderService');
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

    _logger.info('Initializing MedicationReminderService...');
    
    // Initialize timezone data first
    tz_data.initializeTimeZones();
    
    await _initializeNotifications();
    _isInitialized = true;
    _logger.info('MedicationReminderService initialized successfully.');
  }

  Future<void> _initializeNotifications() async {
    _logger.info('Initializing notification plugin...');
    
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

    // Handle notification responses
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channels AFTER initialization
    await _createNotificationChannels();

    _logger.info('Notification plugin initialized successfully.');
  }

  void _handleNotificationResponse(NotificationResponse details) {
    _logger.info('Notification tapped: ${details.payload}');

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
    final plugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      // Request permissions first
      await plugin.requestNotificationsPermission();
      await plugin.requestExactAlarmsPermission();

      // For alarm-style reminders (higher importance)
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        _medicationAlarmChannelId,
        'Medication Alarms',
        description: 'High priority medication alarms',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      // For standard reminders
      const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
        _medicationChannelId,
        'Medication Reminders',
        description: 'Notifications for medication reminders',
        importance: Importance.high,
        playSound: true,
      );

      await plugin.createNotificationChannel(alarmChannel);
      await plugin.createNotificationChannel(medicationChannel);
    }
  }

  Future<void> addMedicationReminder(MedicationReminder reminder) async {
    if (!_isInitialized) {
      _logger.severe('Error: MedicationReminderService not initialized.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No user logged in.');
      return;
    }

    _logger.info('Adding reminder for user: ${user.uid}');
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicationReminders')
          .doc(reminder.id)
          .set(reminder.toMap());

      _logger.info('Reminder saved to Firestore: ${reminder.toMap()}');
      await _scheduleNotification(reminder);
    } catch (e) {
      _logger.severe('Error adding medication reminder: $e');
    }
  }

  Future<void> _scheduleNotification(MedicationReminder reminder) async {
    _logger.info('Scheduling notification for reminder: ${reminder.id}');

    final androidDetails = AndroidNotificationDetails(
      _medicationAlarmChannelId,
      'Medication Alarms',
      channelDescription: 'High priority medication alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      // Remove ongoing: true for scheduled notifications
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'medication_alarm',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = '${reminder.id}|${reminder.medicineName}|${reminder.dosage}';

    try {
      if (reminder.isRecurring) {
        _logger.info('Setting up recurring notifications...');
        for (final day in reminder.daysToRepeat) {
          final nextDay = _nextInstanceOfDay(day, reminder.timeToTake);
          _logger.info('Next instance for weekday $day: $nextDay');
          
          // Check if the scheduled time is in the future
          if (nextDay.isAfter(tz.TZDateTime.now(tz.local))) {
            await _notificationsPlugin.zonedSchedule(
              reminder.id.hashCode + day, // Unique ID for each day
              'Time to take ${reminder.medicineName}!',
              '${reminder.dosage} - Tap to stop alarm',
              nextDay,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: payload,
            );
          }
        }
      } else {
        _logger.info('Setting one-time notification...');
        final scheduledTime = tz.TZDateTime.from(reminder.timeToTake, tz.local);
        _logger.info('Scheduled time: $scheduledTime');
        
        // Check if the scheduled time is in the future
        if (scheduledTime.isAfter(tz.TZDateTime.now(tz.local))) {
          await _notificationsPlugin.zonedSchedule(
            reminder.id.hashCode,
            'Time to take ${reminder.medicineName}!',
            '${reminder.dosage} - Tap to stop alarm',
            scheduledTime,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
        } else {
          _logger.warning('Scheduled time is in the past: $scheduledTime');
        }
      }

      _logger.info('Notification scheduled successfully');
    } catch (e) {
      _logger.severe('Error scheduling notification: $e');
      rethrow;
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

  // Play alarm directly in app
  Future<void> _playAlarm(MedicationReminder reminder) async {
    _logger.info('Playing alarm for reminder: ${reminder.id}');
    _currentlyPlayingAlarmId = reminder.id;
    
    try {
      // Create a new AudioPlayer instance for this alarm
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
        audioPlayer.dispose();
      });
    } catch (e) {
      _logger.severe('Error playing alarm: $e');
    }
  }

  Future<void> _showAlarmNotification(MedicationReminder reminder) async {
    final androidDetails = AndroidNotificationDetails(
      _medicationAlarmChannelId,
      'Medication Alarms',
      channelDescription: 'High priority medication alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true, // This is fine for active alarms
      color: const Color(0xFF2C5364),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      categoryIdentifier: 'medication_alarm',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

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

  Future<List<MedicationReminder>> getMedicationReminders() async {
    if (!_isInitialized) {
      _logger.severe('Error: MedicationReminderService not initialized.');
      return [];
    }

    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No user logged in.');
      return [];
    }

    _logger.info('Fetching reminders for user: ${user.uid}');
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicationReminders')
          .orderBy('timeToTake')
          .get();

      final reminders = snapshot.docs
          .map((doc) => MedicationReminder.fromMap(doc.data()))
          .toList();
      _logger.info('Fetched ${reminders.length} reminders.');
      return reminders;
    } catch (e) {
      _logger.severe('Error fetching medication reminders: $e');
      return [];
    }
  }

  Future<void> deleteMedicationReminder(String reminderId) async {
    if (!_isInitialized) {
      _logger.severe('Error: MedicationReminderService not initialized.');
      return;
    }

    _logger.info('Deleting reminder: $reminderId');
    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No user logged in.');
      return;
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('medicationReminders')
          .doc(reminderId)
          .delete();

      // Cancel all notifications for this reminder (including recurring ones)
      await _notificationsPlugin.cancel(reminderId.hashCode);
      
      // For recurring reminders, cancel all day-specific notifications
      for (int day = 1; day <= 7; day++) {
        await _notificationsPlugin.cancel(reminderId.hashCode + day);
      }

      // Stop alarm if it's playing
      await _stopAlarm(reminderId);

      _logger.info('Reminder and its notification cancelled.');
    } catch (e) {
      _logger.severe('Error deleting medication reminder: $e');
    }
  }

  Future<void> updateMedicationReminder(MedicationReminder reminder) async {
    if (!_isInitialized) {
      _logger.severe('Error: MedicationReminderService not initialized.');
      return;
    }

    _logger.info('Updating reminder: ${reminder.id}');
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
      _logger.severe('Error: MedicationReminderService not initialized.');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _logger.warning('No user logged in.');
      return;
    }

    _logger.info('Clearing all reminders for user: ${user.uid}');
    try {
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

      _logger.info('All medication reminders cleared successfully.');
    } catch (e) {
      _logger.severe('Error clearing all reminders: $e');
    }
  }

  /// Test method to schedule a notification in 10 seconds for debugging
  Future<void> testNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    final testTime = DateTime.now().add(const Duration(seconds: 10));
    final testReminder = MedicationReminder(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      medicineName: 'Test Medicine',
      dosage: '1 tablet',
      timeToTake: testTime,
    );

    _logger.info('Scheduling test notification for: $testTime');
    await _scheduleNotification(testReminder);
  }
}