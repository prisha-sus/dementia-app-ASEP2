import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Import your service file
import 'package:mytestapp/services/medicinealert.dart';

class MedicationAlertScreen extends StatefulWidget {
  const MedicationAlertScreen({super.key});

  @override
  _MedicationAlertScreenState createState() => _MedicationAlertScreenState();
}

class _MedicationAlertScreenState extends State<MedicationAlertScreen> {
  final _logger = Logger('MedicationAlertScreen');
  final MedicationReminderService _reminderService =
      MedicationReminderService();
  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Replace with your actual IP address
  static final String _backendUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:5000';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _requestNotificationPermissions();
    _initializeTimeZone();
    _initializeLogging();
    _initializeService();
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      // For Android 13+ (API 33+), request notification permission using the main plugin instance
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // The permission request for Android 13+ should be handled in the main app using the permission_handler package or NotificationPermission.request()
      // See: https://pub.dev/packages/flutter_local_notifications#android-13-notification-permission
    }
  }

  Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
  }

  void _initializeLogging() {
    try {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        developer.log(
          record.message,
          time: record.time,
          name: record.loggerName,
          level: record.level.value,
          error: record.error,
          stackTrace: record.stackTrace,
        );
        // Also print to console for debugging
        print('[${record.level.name}] ${record.loggerName}: ${record.message}');
      });
      _logger.info('Logging initialized successfully');
      print('DEBUG: Logging system initialized'); // Fallback debug print
    } catch (e) {
      print('ERROR: Failed to initialize logging: $e');
    }
  }

  Future<void> _initializeService() async {
    print('DEBUG: Starting initialization...');
    _logger.info('Starting initialization...');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize service with timeout
      print('DEBUG: Initializing reminder service...');
      await _reminderService.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Service initialization timed out');
        },
      );

      print('DEBUG: Reminder service initialized successfully');
      _logger.info('Reminder service initialized');

      if (!mounted) return;

      await _loadReminders();
      _startReminderCheck();
    } catch (e, stack) {
      print('ERROR: Initialization failed: $e');
      print('STACK: $stack');
      _logger.severe('Initialization error', e, stack);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;

    print('DEBUG: Loading reminders...');
    _logger.info('Loading reminders...');

    try {
      // Add timeout to prevent hanging
      final reminders = await _reminderService.getMedicationReminders().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Loading reminders timed out', const Duration(seconds: 10));
        },
      );

      print('DEBUG: Successfully loaded ${reminders.length} reminders');
      _logger.info('Successfully loaded ${reminders.length} reminders');

      if (!mounted) return;

      setState(() {
        _reminders = reminders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e, stack) {
      print('ERROR: Failed to load reminders: $e');
      print('STACK: $stack');
      _logger.severe('Error loading reminders', e, stack);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading reminders: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reminders: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Function to trigger dispense via HTTP POST
  Future<void> triggerDispense(MedicationReminder reminder) async {
    _logger.info('Triggering dispense for: ${reminder.medicineName}');
    print('DEBUG: Triggering dispense for: ${reminder.medicineName}');

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/dispense'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'medication_name': reminder.medicineName,
              'dosage': reminder.dosage,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _logger.info('Dispense triggered successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Dispensing ${reminder.medicineName} - ${reminder.dosage}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _logger.severe('Failed to trigger dispense: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to dispense medication'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('ERROR: Dispense failed: $e');
      _logger.severe('Error triggering dispense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error connecting to dispenser'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to check if any reminder should be triggered
  void _startReminderCheck() {
    print('DEBUG: Starting periodic reminder checks');
    _logger.info('Starting periodic reminder checks');

    // Check every minute for reminders
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (mounted) {
        _checkReminders();
      }
    });
  }

  void _checkReminders() {
    _logger.fine('Checking reminders at ${DateTime.now()}');
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentWeekday = now.weekday;

    for (final reminder in _reminders) {
      final reminderTime = TimeOfDay.fromDateTime(reminder.timeToTake);

      _logger.info(
          'Checking reminder: ${reminder.medicineName} scheduled for ${reminderTime.format(context)}');

      // Check if current time matches reminder time (within 1 minute)
      if (_timesMatch(currentTime, reminderTime)) {
        _logger.info('Time matches for reminder: ${reminder.medicineName}');

        if (reminder.isRecurring) {
          // Check if today is one of the recurring days
          if (reminder.daysToRepeat.contains(currentWeekday)) {
            _logger.info(
                'Triggering recurring reminder: ${reminder.medicineName}');
            _showNotification(reminder);
            triggerDispense(reminder);
          }
        } else {
          // Check if today is the scheduled date
          if (_isSameDate(now, reminder.timeToTake)) {
            _logger
                .info('Triggering one-time reminder: ${reminder.medicineName}');
            _showNotification(reminder);
            triggerDispense(reminder);
          }
        }
      }
    }
  }

  Future<void> _showNotification(MedicationReminder reminder) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Notifications for medication reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      reminder.id.hashCode,
      'Medicine Reminder',
      'Time to take ${reminder.medicineName} - ${reminder.dosage}',
      platformDetails,
    );

    _logger.info('Notification shown for: ${reminder.medicineName}');
  }

  bool _timesMatch(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour == time2.hour && time1.minute == time2.minute;
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final local = Localizations.of(context, AppLocalizations);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          local.medicationReminders,
          style: TextStyle(
              color: colorScheme.onPrimary,
              fontFamily: GoogleFonts.nunito().fontFamily,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
      ),
      body: _buildBody(context, local, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditReminderDialog(),
        backgroundColor: colorScheme.surface,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations local, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading reminders...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeService(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined,
                size: 80, color: colorScheme.surface),
            const SizedBox(height: 16),
            Text(
              local.noMedicationReminders,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              local.tapToAddReminder,
              style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder);
      },
    );
  }

  Widget _buildReminderCard(MedicationReminder reminder) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final local = Localizations.of(context, AppLocalizations);
    final timeFormat = DateFormat('h:mm a');
    String scheduleText = reminder.isRecurring
        ? '${local.every} ${_getDaysText(reminder.daysToRepeat)} ${local.at} ${timeFormat.format(reminder.timeToTake)}'
        : '${local.oneTimeAt} ${timeFormat.format(reminder.timeToTake)} ${local.on} ${DateFormat('MMM d, yyyy').format(reminder.timeToTake)}';

    return Card(
      color: colorScheme.secondary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAddEditReminderDialog(reminder: reminder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medication,
                      color: theme.scaffoldBackgroundColor, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.medicineName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_arrow,
                        color: colorScheme.primary, size: 28),
                    onPressed: () => triggerDispense(reminder),
                    tooltip: 'Dispense Now',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: colorScheme.tertiary, size: 28),
                    onPressed: () => _confirmDelete(reminder),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${local.dosage} ${reminder.dosage}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                scheduleText,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaysText(List<int> days) {
    if (days.length == 7) return 'day';

    List<String> dayNames = [];
    List<String> weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    for (int day in days) {
      dayNames.add(weekdays[day - 1]);
    }

    return dayNames.join(', ');
  }

  Future<void> _confirmDelete(MedicationReminder reminder) async {
    _logger.info('Confirming deletion of reminder: ${reminder.id}');
    final colorScheme = Theme.of(context).colorScheme;
    final local = Localizations.of(context, AppLocalizations);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(local.deleteReminderTitle),
        content:
            Text('${local.deleteReminderContent} ${reminder.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(local.cancel,
                style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reminderService.deleteMedicationReminder(reminder.id);
              _loadReminders();
            },
            child: Text(local.delete,
                style: TextStyle(color: colorScheme.tertiary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditReminderDialog(
      {MedicationReminder? reminder}) async {
    _logger
        .info('Showing ${reminder == null ? "add" : "edit"} reminder dialog');
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final local = Localizations.of(context, AppLocalizations);

    final TextEditingController medicineNameController = TextEditingController(
      text: reminder?.medicineName ?? '',
    );
    final TextEditingController dosageController = TextEditingController(
      text: reminder?.dosage ?? '',
    );

    TimeOfDay selectedTime = reminder != null
        ? TimeOfDay.fromDateTime(reminder.timeToTake)
        : TimeOfDay.now();

    DateTime selectedDate = reminder?.timeToTake ?? DateTime.now();
    bool isRecurring = reminder?.isRecurring ?? false;

    List<bool> daysSelected = List.filled(7, false);
    if (reminder != null && reminder.isRecurring) {
      for (int day in reminder.daysToRepeat) {
        daysSelected[day - 1] = true;
      }
    } else {
      daysSelected = [true, true, true, true, true, false, false];
    }

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(reminder == null
                  ? local.addMedicationReminder
                  : local.editMedicationReminder),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: medicineNameController,
                      decoration: InputDecoration(
                        labelText: local.medicationName,
                        prefixIcon:
                            Icon(Icons.medication, color: colorScheme.tertiary),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: colorScheme.tertiary, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: colorScheme.tertiary.withOpacity(0.5),
                              width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageController,
                      decoration: InputDecoration(
                        labelText: local.dosage,
                        prefixIcon:
                            Icon(Icons.medication, color: colorScheme.tertiary),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: colorScheme.tertiary, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: colorScheme.tertiary.withOpacity(0.5),
                              width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Text(local.time,
                            style: TextStyle(
                                fontSize: 16, color: colorScheme.tertiary)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogTheme: DialogThemeData(
                                        backgroundColor:
                                            theme.scaffoldBackgroundColor),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              setStateDialog(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text(
                            selectedTime.format(context),
                            style: TextStyle(
                                fontSize: 16, color: colorScheme.tertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(local.recurringReminder,
                          style: TextStyle(
                              fontSize: 16, color: colorScheme.tertiary)),
                      activeColor: colorScheme.primary,
                      activeTrackColor: colorScheme.primary.withOpacity(0.5),
                      inactiveThumbColor: colorScheme.tertiary,
                      inactiveTrackColor: colorScheme.tertiary.withOpacity(0.4),
                      value: isRecurring,
                      onChanged: (value) {
                        setStateDialog(() {
                          isRecurring = value;
                        });
                      },
                    ),
                    if (!isRecurring)
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: colorScheme.tertiary),
                          const SizedBox(width: 8),
                          Text(local.date,
                              style: TextStyle(
                                  fontSize: 16, color: colorScheme.tertiary)),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      dialogTheme: DialogThemeData(
                                          backgroundColor:
                                              theme.scaffoldBackgroundColor),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Text(
                              DateFormat('MMM d, yyyy').format(selectedDate),
                              style: TextStyle(
                                  fontSize: 16, color: colorScheme.tertiary),
                            ),
                          ),
                        ],
                      ),
                    if (isRecurring) ...[
                      const SizedBox(height: 16),
                      Text(local.repeatOnDays,
                          style: TextStyle(
                              fontSize: 16, color: colorScheme.tertiary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final weekdayNames = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          return ChoiceChip(
                            label: Text(weekdayNames[index],
                                style: const TextStyle(fontSize: 14)),
                            selected: daysSelected[index],
                            onSelected: (selected) {
                              setStateDialog(() {
                                daysSelected[index] = selected;
                              });
                            },
                            selectedColor: colorScheme.primary,
                            backgroundColor: theme.scaffoldBackgroundColor,
                            labelStyle: TextStyle(
                              color: daysSelected[index]
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(local.cancel,
                      style: TextStyle(color: colorScheme.tertiary)),
                ),
                TextButton(
                  onPressed: () async {
                    if (medicineNameController.text.trim().isEmpty ||
                        dosageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(local.pleaseFillAllFields)),
                      );
                      return;
                    }

                    if (isRecurring && !daysSelected.contains(true)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(local.pleaseSelectAtLeastOneDay)),
                      );
                      return;
                    }

                    final now = DateTime.now();
                    DateTime timeToTake = isRecurring
                        ? DateTime(now.year, now.month, now.day,
                            selectedTime.hour, selectedTime.minute)
                        : DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute);

                    List<int> daysToRepeat = [];
                    if (isRecurring) {
                      for (int i = 0; i < 7; i++) {
                        if (daysSelected[i]) {
                          daysToRepeat.add(i + 1);
                        }
                      }
                    }

                    final MedicationReminder newReminder = MedicationReminder(
                      id: reminder?.id ?? const Uuid().v4(),
                      medicineName: medicineNameController.text.trim(),
                      dosage: dosageController.text.trim(),
                      timeToTake: timeToTake,
                      isRecurring: isRecurring,
                      daysToRepeat: daysToRepeat,
                    );

                    Navigator.pop(context);

                    try {
                      if (reminder == null) {
                        await _reminderService
                            .addMedicationReminder(newReminder);
                      } else {
                        await _reminderService
                            .updateMedicationReminder(newReminder);
                      }
                      _loadReminders();
                    } catch (e) {
                      print('ERROR: Failed to save reminder: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Failed to save reminder: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    reminder == null ? local.add : local.update,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
