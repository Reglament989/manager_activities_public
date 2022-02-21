import 'package:flutter/material.dart';
import 'package:manager_activites/create_event/create_event.dart';
import 'package:manager_activites/home/data/event_loader.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarGrid extends StatefulWidget {
  final void Function(DateTime, DateTime, List<CalendarEvent>?) onDaySelected;
  final Map<DateTime, List<CalendarEvent>> events;
  CalendarGrid({Key? key, required this.onDaySelected, required this.events});

  @override
  _CalendarGridState createState() => _CalendarGridState(onDaySelected, events);
}

class _CalendarGridState extends State<CalendarGrid> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  void Function(DateTime, DateTime, List<CalendarEvent>?) _onDaySelected;
  final Map<DateTime, List<CalendarEvent>> events;

  _CalendarGridState(this._onDaySelected, this.events);

  @override
  void initState() {
    _focusedDay = DateTime.now();
    super.initState();
  }

  List<CalendarEvent> getEventsByDay(DateTime day) {
    if (events.containsKey(day)) {
      return events[day]!;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}
