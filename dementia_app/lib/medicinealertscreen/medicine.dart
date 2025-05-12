import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
    _loadReminders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        backgroundColor: const Color(0xFF2C5364),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medication_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No medication reminders',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the + button to add a reminder',
                        style: TextStyle(color: Colors.grey),
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
        backgroundColor: const Color(0xFF2C5364),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(MedicationReminder reminder) {
    final timeFormat = DateFormat('h:mm a');
    String scheduleText = reminder.isRecurring
        ? 'Every ${_getDaysText(reminder.daysToRepeat)} at ${timeFormat.format(reminder.timeToTake)}'
        : 'One time at ${timeFormat.format(reminder.timeToTake)} on ${DateFormat('MMM d, yyyy').format(reminder.timeToTake)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
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
                  const Icon(Icons.medication, color: Color(0xFF2C5364)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.medicineName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(reminder),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dosage: ${reminder.dosage}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                scheduleText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text(
            'Are you sure you want to delete the reminder for ${reminder.medicineName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reminderService.deleteMedicationReminder(reminder.id);
              _loadReminders();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEditReminderDialog(
      {MedicationReminder? reminder}) async {
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
              title: Text(reminder == null
                  ? 'Add Medication Reminder'
                  : 'Edit Medication Reminder'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: medicineNameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        prefixIcon: Icon(Icons.medication),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        prefixIcon: Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Time:', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (pickedTime != null) {
                              setStateDialog(() {
                                selectedTime = pickedTime;
                              });
                            }
                          },
                          child: Text(
                            selectedTime.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Recurring Reminder'),
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
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Date:', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setStateDialog(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: Text(
                              DateFormat('MMM d, yyyy').format(selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    if (isRecurring) ...[
                      const SizedBox(height: 16),
                      const Text('Repeat on days:'),
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
                            label: Text(weekdayNames[index]),
                            selected: daysSelected[index],
                            onSelected: (selected) {
                              setStateDialog(() {
                                daysSelected[index] = selected;
                              });
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            backgroundColor: Colors.grey[200],
                            labelStyle: TextStyle(
                              color: daysSelected[index]
                                  ? Colors.white
                                  : Colors.black,
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
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    if (medicineNameController.text.trim().isEmpty ||
                        dosageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    if (isRecurring && !daysSelected.contains(true)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select at least one day')),
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
                  child: Text(reminder == null ? 'ADD' : 'UPDATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
