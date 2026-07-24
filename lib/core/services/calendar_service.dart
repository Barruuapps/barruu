import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Event types for calendar
enum EventType {
  assignmentDeadline,
  classSchedule,
  studySession,
  writingGoal,
  meeting,
  projectDeadline,
  personalReminder,
  appEvent,
}

/// Event priority levels
enum EventPriority { high, normal, low }

/// Recurrence patterns for events
enum RecurrencePattern { none, daily, weekly, monthly, yearly }

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType type;
  final String? linkedDocumentId;
  final bool allDay;
  final RecurrencePattern recurrence;
  final List<DateTime> reminderTimes;
  final String color;
  final EventPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.linkedDocumentId,
    this.allDay = false,
    this.recurrence = RecurrencePattern.none,
    this.reminderTimes = const [],
    this.color = '#2196F3',
    this.priority = EventPriority.normal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'linkedDocumentId': linkedDocumentId,
      'allDay': allDay,
      'recurrence': recurrence.name,
      'reminderTimes': reminderTimes.map((e) => e.toIso8601String()).toList(),
      'color': color,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: EventType.values.firstWhere((e) => e.name == json['type']),
      linkedDocumentId: json['linkedDocumentId'],
      allDay: json['allDay'],
      recurrence: RecurrencePattern.values.firstWhere(
        (e) => e.name == json['recurrence'],
      ),
      reminderTimes: (json['reminderTimes'] as List)
          .map((e) => DateTime.parse(e))
          .toList(),
      color: json['color'],
      priority: EventPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Create a copy with updated fields
  CalendarEvent copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventType? type,
    String? linkedDocumentId,
    bool? allDay,
    RecurrencePattern? recurrence,
    List<DateTime>? reminderTimes,
    String? color,
    EventPriority? priority,
  }) {
    return CalendarEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      linkedDocumentId: linkedDocumentId ?? this.linkedDocumentId,
      allDay: allDay ?? this.allDay,
      recurrence: recurrence ?? this.recurrence,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      color: color ?? this.color,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Service for managing calendar events
class CalendarService {
  static const String _storageKey = 'calendar_events';
  final Uuid _uuid = const Uuid();

  /// Get all events
  Future<List<CalendarEvent>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(_storageKey);

    if (eventsJson == null) return [];

    final List<dynamic> eventsList = json.decode(eventsJson);
    return eventsList.map((e) => CalendarEvent.fromJson(e)).toList();
  }

  /// Get events for a specific date
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    final allEvents = await getAllEvents();
    final targetDate = DateTime(date.year, date.month, date.day);

    return allEvents.where((event) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      return eventDate == targetDate;
    }).toList();
  }

  /// Get events for a date range (inclusive)
  Future<List<CalendarEvent>> getEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final allEvents = await getAllEvents();

    return allEvents.where((event) {
      return event.startTime.isAfter(start) ||
          event.startTime.isAtSameMomentAs(start) &&
              event.startTime.isBefore(end) ||
          event.startTime.isAtSameMomentAs(end);
    }).toList();
  }

  /// Add new event
  Future<CalendarEvent> addEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required EventType type,
    String? linkedDocumentId,
    bool allDay = false,
    RecurrencePattern recurrence = RecurrencePattern.none,
    List<DateTime>? reminderTimes,
    String color = '#2196F3',
    EventPriority priority = EventPriority.normal,
  }) async {
    final event = CalendarEvent(
      id: _uuid.v4(),
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      type: type,
      linkedDocumentId: linkedDocumentId,
      allDay: allDay,
      recurrence: recurrence,
      reminderTimes: reminderTimes ?? [],
      color: color,
      priority: priority,
    );

    final events = await getAllEvents();
    events.add(event);
    await _saveEvents(events);

    return event;
  }

  /// Update existing event
  Future<void> updateEvent(CalendarEvent event) async {
    final events = await getAllEvents();
    final index = events.indexWhere((e) => e.id == event.id);

    if (index != -1) {
      events[index] = event.copyWith();
      await _saveEvents(events);
    }
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    final events = await getAllEvents();
    events.removeWhere((e) => e.id == eventId);
    await _saveEvents(events);
  }

  /// Get upcoming events (next 7 days)
  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    return getEventsInRange(now, future);
  }

  /// Get events by type
  Future<List<CalendarEvent>> getEventsByType(EventType type) async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => e.type == type).toList();
  }

  /// Search events by title or description
  Future<List<CalendarEvent>> searchEvents(String query) async {
    final allEvents = await getAllEvents();
    final lowerQuery = query.toLowerCase();

    return allEvents.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          event.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Check for conflicts with existing events
  Future<List<CalendarEvent>> findConflicts(
    DateTime start,
    DateTime end,
  ) async {
    final allEvents = await getAllEvents();

    return allEvents.where((event) {
      return (start.isBefore(event.endTime) && end.isAfter(event.startTime));
    }).toList();
  }

  /// Get events count for a month
  Future<Map<DateTime, int>> getMonthEventCounts(int year, int month) async {
    final allEvents = await getAllEvents();
    final Map<DateTime, int> counts = {};

    final firstDay = DateTime(year, month);
    final lastDay = DateTime(year, month + 1, 0);

    for (var event in allEvents) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      if (eventDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(lastDay.add(const Duration(days: 1)))) {
        counts[eventDate] = (counts[eventDate] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Save events to storage
  Future<void> _saveEvents(List<CalendarEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = json.encode(events.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, eventsJson);
  }

  /// Clear all events (use with caution)
  Future<void> clearAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

/// Provider for calendar service
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

/// Provider for all calendar events
final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.watch(calendarServiceProvider);
  return service.getAllEvents();
});

/// Provider for upcoming events
final upcomingEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.watch(calendarServiceProvider);
  return service.getUpcomingEvents();
});

/// Provider for events on a specific date
final eventsForDateProvider =
    FutureProvider.family<List<CalendarEvent>, DateTime>((ref, date) async {
      final service = ref.watch(calendarServiceProvider);
      return service.getEventsForDate(date);
    });
