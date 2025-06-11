import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:mytestapp/flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import your service file
import 'package:mytestapp/services/medicinealert.dart';
// import 'package:mytestapp/main.dart';

class MedicationAlertScreen extends StatefulWidget {
  const MedicationAlertScreen({super.key});

  @override
  _MedicationAlertScreenState createState() => _MedicationAlertScreenState();
}

class _MedicationAlertScreenState extends State<MedicationAlertScreen> {
  final MedicationReminderService _reminderService =
      MedicationReminderService();
  List<MedicationReminder> _reminders = [];
  bool _isLoading = true;

  // Replace with your actual IP address
  static const String _backendUrl = 'http://192.168.191.125:5000';

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _startReminderCheck(); // Start checking for reminders
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    final reminders = await _reminderService.getMedicationReminders();

    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  // Function to trigger dispense via HTTP POST
  Future<void> triggerDispense(MedicationReminder reminder) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/dispense'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'medication_name': reminder.medicineName,
          'dosage': reminder.dosage,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print('Dispense triggered successfully for ${reminder.medicineName}');
        // Show success notification to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dispensing ${reminder.medicineName} - ${reminder.dosage}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Failed to trigger dispense: ${response.statusCode}');
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
      print('Error triggering dispense: $e');
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
    // Check every minute for reminders
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      _checkReminders();
    });
  }

  void _checkReminders() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday

    for (final reminder in _reminders) {
      final reminderTime = TimeOfDay.fromDateTime(reminder.timeToTake);
      
      // Check if current time matches reminder time (within 1 minute)
      if (_timesMatch(currentTime, reminderTime)) {
        if (reminder.isRecurring) {
          // Check if today is one of the recurring days
          if (reminder.daysToRepeat.contains(currentWeekday)) {
            triggerDispense(reminder);
          }
        } else {
          // Check if today is the scheduled date
          if (_isSameDate(now, reminder.timeToTake)) {
            triggerDispense(reminder);
          }
        }
      }
    }
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title:  Text(local.medicationReminders, style: TextStyle(color: colorScheme.onPrimary, fontFamily: GoogleFonts.nunito().fontFamily, fontWeight: FontWeight.bold) ,),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.medication_outlined,
                          size: 80, color: colorScheme.surface),
                      const SizedBox(height: 16),
                       Text(
                        local.noMedicationReminders,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                      ),
                      const SizedBox(height: 8),
                       Text(
                        local.tapToAddReminder,
                        style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    return _buildReminderCard(reminder);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditReminderDialog(),
        backgroundColor: colorScheme.surface,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(MedicationReminder reminder) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = Theme.of(context);
    final local = Localizations.of(context, AppLocalizations);
    final timeFormat = DateFormat('h:mm a');
    String scheduleText = reminder.isRecurring
        ? '${local.every} ${_getDaysText(reminder.daysToRepeat)} ${local.at} ${timeFormat.format(reminder.timeToTake)}'
        : '${local.oneTimeAt} ${timeFormat.format(reminder.timeToTake)} ${local.on} ${DateFormat('MMM d, yyyy',).format(reminder.timeToTake)}';

    return Card(
      color: colorScheme.secondary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),),
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
                   Icon(Icons.medication, color: theme.scaffoldBackgroundColor, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.medicineName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Add manual dispense button
                  IconButton(
                    icon: Icon(Icons.play_arrow, color: colorScheme.primary, size: 28),
                    onPressed: () => triggerDispense(reminder),
                    tooltip: 'Dispense Now',
                  ),
                    IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.tertiary, size: 28),
                    onPressed: () => _confirmDelete(reminder),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${local.dosage} ${reminder.dosage}',
                style: const TextStyle(fontSize: 18,fontWeight: FontWeight.w700 ),
              ),
              const SizedBox(height: 6),
              Text(
                scheduleText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
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
      // Convert from 1-7 (Monday-Sunday) to 0-6 (index for weekdays list)
      dayNames.add(weekdays[day - 1]);
    }

    return dayNames.join(', ');
  }

  Future<void> _confirmDelete(MedicationReminder reminder) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final local = Localizations.of(context, AppLocalizations);
    return showDialog(
      //color: theme.scaffoldBackgroundColor,
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(local.deleteReminderTitle),
        content: Text(
            '${local.deleteReminderContent} ${reminder.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(local.cancel, style: TextStyle(color: colorScheme.primary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reminderService.deleteMedicationReminder(reminder.id);
              _loadReminders();
            },
            child:  Text(local.delete, style: TextStyle(color: colorScheme.tertiary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditReminderDialog(
      {MedicationReminder? reminder}) async {
        final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
        final textTheme = Theme.of(context).textTheme;
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

    // Initialize days to repeat - default to all weekdays if new reminder
    List<bool> daysSelected = List.filled(7, false);
    if (reminder != null && reminder.isRecurring) {
      for (int day in reminder.daysToRepeat) {
        // Convert from 1-7 to 0-6 index
        daysSelected[day - 1] = true;
      }
    } else {
      // Default to weekdays selected
      daysSelected = [true, true, true, true, true, false, false];
    }

    return showDialog(
      
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: reminder == null
      ? theme.scaffoldBackgroundColor  
      : theme.scaffoldBackgroundColor,
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
    prefixIcon: Icon(Icons.medication, color: colorScheme.tertiary),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.tertiary, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.tertiary.withOpacity(0.5), width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    labelStyle: TextStyle(
      color: FocusScope.of(context).hasFocus
          ? colorScheme.tertiary
          : colorScheme.tertiary.withOpacity(0.5),
    ),
  ),
),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageController,
                      decoration: InputDecoration(
    labelText: local.dosage,
    prefixIcon: Icon(Icons.medication, color: colorScheme.tertiary),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.tertiary, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: colorScheme.tertiary.withOpacity(0.5), width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    labelStyle: TextStyle(
      color: FocusScope.of(context).hasFocus
          ? colorScheme.tertiary
          : colorScheme.tertiary.withOpacity(0.5),
    ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                         Icon(Icons.access_time, color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                         Text(local.time, style: TextStyle(fontSize: 16, color: colorScheme.tertiary)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary, // header, selected time, OK button
              onPrimary: colorScheme.onPrimary, // text on header/OK
              //: theme.scaffoldBackgroundColor, // dialog background
              //onSurface: colorScheme.onSurface, // text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.tertiary, // OK button color
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: theme.scaffoldBackgroundColor),
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
                            style: TextStyle(fontSize: 16, color: colorScheme.tertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(local.recurringReminder, style: TextStyle(fontSize: 16, color: colorScheme.tertiary)),
                      activeColor: colorScheme.primary, // Thumb color when ON
  activeTrackColor: colorScheme.primary.withOpacity(0.5), // Track color when ON
  inactiveThumbColor: colorScheme.tertiary, // Thumb color when OFF (distinct but solid)
  inactiveTrackColor: colorScheme.tertiary.withOpacity(0.4), // Track color when OFF (muted version)// <-- Track color when OFF (optional)
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
                           Icon(Icons.calendar_today, color:colorScheme.tertiary),
                          const SizedBox(width: 8),
                           Text(local.date, style: TextStyle(fontSize: 16, color: colorScheme.tertiary)),
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
      final colorScheme = Theme.of(context).colorScheme;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: colorScheme.primary, // header, selected day
            onPrimary: colorScheme.onPrimary, // text on header
            //surface: colorScheme.surface, // dialog background
            //onSurface: colorScheme.onSurface, // text color
          ), dialogTheme: DialogThemeData(backgroundColor: theme.scaffoldBackgroundColor),
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
                              style:  TextStyle(fontSize: 16, color: colorScheme.tertiary),
                            ),
                          ),
                        ],
                      ),
                    if (isRecurring) ...[
                      const SizedBox(height: 16),
                       Text(local.repeatOnDays, style: TextStyle(fontSize: 16, color: colorScheme.tertiary)),
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
                            label: Text(weekdayNames[index], style: TextStyle(fontSize: 14)),
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
                  child:  Text(local.cancel, style: TextStyle(color: colorScheme.tertiary)),
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

                    // Convert selected time to DateTime
                    final now = DateTime.now();
                    DateTime timeToTake = isRecurring
                        ? DateTime(
                            now.year,
                            now.month,
                            now.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          )
                        : DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                    // Convert days selected to our format (1-7 for Monday-Sunday)
                    List<int> daysToRepeat = [];
                    if (isRecurring) {
                      for (int i = 0; i < 7; i++) {
                        if (daysSelected[i]) {
                          // Convert from 0-6 to 1-7
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

                    if (reminder == null) {
                      await _reminderService.addMedicationReminder(newReminder);
                    } else {
                      await _reminderService
                          .updateMedicationReminder(newReminder);
                    }

                    _loadReminders();
                  },
                  child: Text(reminder == null ? local.add : local.update, style: TextStyle(color: colorScheme.primary),)
                ),
              ],
            );
          },
        );
      },
    );
  }
}