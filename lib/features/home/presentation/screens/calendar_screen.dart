import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:barruu/core/services/calendar_service.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

/// Calendar screen for managing events
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarService = ref.watch(calendarServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(IconsaxPlusLinear.add_circle),
            onPressed: () => _showAddEventDialog(context),
            tooltip: 'Add Event',
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<Map<DateTime, int>>(
            future: calendarService.getMonthEventCounts(
              _focusedDay.year,
              _focusedDay.month,
            ),
            builder: (context, snapshot) {
              final eventCounts = snapshot.data ?? {};

              return TableCalendar(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                eventLoader: (day) {
                  final normalizedDate = DateTime(day.year, day.month, day.day);
                  final count = eventCounts[normalizedDate] ?? 0;
                  return List.generate(count, (index) => index);
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          Expanded(
            child: _selectedDay != null
                ? _buildEventsForDay(_selectedDay!, calendarService)
                : _buildUpcomingEvents(calendarService),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsForDay(DateTime day, CalendarService service) {
    return FutureBuilder<List<CalendarEvent>>(
      future: service.getEventsForDate(day),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: ShimmerCircularProgress(size: 40));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconsaxPlusLinear.calendar_1,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No events on ${DateFormat('MMM d, yyyy').format(day)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index]);
          },
        );
      },
    );
  }

  Widget _buildUpcomingEvents(CalendarService service) {
    return FutureBuilder<List<CalendarEvent>>(
      future: service.getUpcomingEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: ShimmerCircularProgress(size: 40));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return const Center(child: Text('No upcoming events'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index]);
          },
        );
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(
            int.parse(event.color.replaceFirst('#', '0xFF')),
          ),
          child: Icon(
            _getIconForEventType(event.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(event.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty)
              Text(
                event.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              event.allDay
                  ? 'All day'
                  : '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (popupContext) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    _showEditEventDialog(context, event);
                  }
                });
              },
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _deleteEvent(event.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForEventType(EventType type) {
    switch (type) {
      case EventType.assignmentDeadline:
        return IconsaxPlusLinear.task_square;
      case EventType.classSchedule:
        return IconsaxPlusLinear.teacher;
      case EventType.studySession:
        return IconsaxPlusLinear.book;
      case EventType.writingGoal:
        return IconsaxPlusLinear.edit;
      case EventType.meeting:
        return IconsaxPlusLinear.people;
      case EventType.projectDeadline:
        return IconsaxPlusLinear.flag;
      case EventType.personalReminder:
        return IconsaxPlusLinear.notification;
      case EventType.appEvent:
        return IconsaxPlusLinear.mobile;
    }
  }

  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    EventType selectedType = EventType.personalReminder;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: EventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getEventTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final startTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  final endTime = startTime.add(const Duration(hours: 1));

                  await ref
                      .read(calendarServiceProvider)
                      .addEvent(
                        title: titleController.text,
                        description: descriptionController.text,
                        startTime: startTime,
                        endTime: endTime,
                        type: selectedType,
                      );

                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, CalendarEvent event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    EventType selectedType = event.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type',
                    border: OutlineInputBorder(),
                  ),
                  items: EventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getEventTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final updatedEvent = event.copyWith(
                    title: titleController.text,
                    description: descriptionController.text,
                    type: selectedType,
                  );

                  await ref
                      .read(calendarServiceProvider)
                      .updateEvent(updatedEvent);

                  if (context.mounted) {
                    Navigator.pop(context);
                    this.setState(() {});
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    await ref.read(calendarServiceProvider).deleteEvent(eventId);
    setState(() {});
  }

  String _getEventTypeName(EventType type) {
    switch (type) {
      case EventType.assignmentDeadline:
        return 'Assignment Deadline';
      case EventType.classSchedule:
        return 'Class Schedule';
      case EventType.studySession:
        return 'Study Session';
      case EventType.writingGoal:
        return 'Writing Goal';
      case EventType.meeting:
        return 'Meeting';
      case EventType.projectDeadline:
        return 'Project Deadline';
      case EventType.personalReminder:
        return 'Personal Reminder';
      case EventType.appEvent:
        return 'App Event';
    }
  }
}
