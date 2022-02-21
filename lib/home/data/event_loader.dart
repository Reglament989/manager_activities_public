import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manager_activites/constants.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/repository/settings.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// TODO: ALL PUT IN CLASS FOR MORE UNDERSTAND!!!!!

final eventsRef = FirebaseFirestore.instance
    .collection('events')
    .withConverter<CalendarEvent>(
      fromFirestore: (snapshot, _) => CalendarEvent.fromJson(snapshot.data()!),
      toFirestore: (event, _) => event.toJson(),
    );

class CalendarChange {
  final String change;
  final String whoCommitted;
  final DateTime whenCommitted;

  factory CalendarChange.fromJson(json) {
    return CalendarChange(json['change'] as String, json['whoCommitted'],
        json['whenCommited'].toDate());
  }

  Map<String, dynamic> toJson() => {
        'change': change,
        'whoCommitted': whoCommitted,
        'whenCommited': Timestamp.fromDate(whenCommitted)
      };

  CalendarChange(this.change, this.whoCommitted, this.whenCommitted);
}

class CalendarEvent {
  final String nameOfActivity;
  final DateTime createdAt;
  final DateTime dateOfActivity;
  final TimeOfDay excatDayOfActivity;
  final TimeOfDay expireTime;
  final String clientId;
  final String numberPhoneOfClient;
  final String note;
  final StatusesSettings status;
  final int countOfHumans;
  final String uid;
  final List<CalendarChange> listChanges;
  final String? owner;

  CalendarEvent(
      {required this.uid,
      required this.countOfHumans,
      required this.createdAt,
      required this.clientId,
      required this.nameOfActivity,
      required this.note,
      required this.numberPhoneOfClient,
      required this.expireTime,
      required this.status,
      required this.dateOfActivity,
      required this.excatDayOfActivity,
      required this.listChanges,
      this.owner});

  factory CalendarEvent.fromJson(json) {
    final listChanges = List<CalendarChange>.from(
        json['listChanges'].map((e) => CalendarChange.fromJson(e)));
    return CalendarEvent(
        uid: json['uid'] as String,
        nameOfActivity: json['nameOfActivity'] as String,
        createdAt: json['createdAt'].toDate(),
        clientId: json['clientId'] as String,
        status: StatusesSettings.fromJson(json['status']),
        countOfHumans: json['countOfHumans'] as int,
        note: json['note'] as String,
        dateOfActivity: json['dateOfActivity'].toDate().toUtc(),
        numberPhoneOfClient: json['numberPhoneOfClient'] as String,
        listChanges: listChanges,
        excatDayOfActivity:
            TimeOfDay.fromDateTime(json['excatDayOfActivity'].toDate()),
        expireTime: TimeOfDay.fromDateTime(json['expireTime'].toDate()),
        owner: json['owner']);
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nameOfActivity': nameOfActivity,
      'createdAt': Timestamp.fromDate(createdAt),
      'clientId': clientId,
      'status': status.toJson(),
      'countOfHumans': countOfHumans,
      'note': note,
      'dateOfActivity': Timestamp.fromDate(dateOfActivity),
      'numberPhoneOfClient': numberPhoneOfClient,
      'listChanges': listChanges.map((e) => e.toJson()).toList(),
      'excatDayOfActivity': Timestamp.fromDate(DateTime(
          1997, 1, 1, excatDayOfActivity.hour, excatDayOfActivity.minute)),
      'expireTime': Timestamp.fromDate(
          DateTime(1997, 1, 1, expireTime.hour, expireTime.minute)),
      'owner': owner
    };
  }

  List<Object> get props => [
        uid,
        nameOfActivity,
        clientId,
        status,
        countOfHumans,
        note,
        dateOfActivity,
        numberPhoneOfClient,
        excatDayOfActivity,
        expireTime
      ];

  static List<String> namingOfProps(BuildContext context) {
    return [
      AppLocalizations.of(context)!.calendarEventPropsUID,
      AppLocalizations.of(context)!.calendarEventPropsNameOfActivity,
      AppLocalizations.of(context)!.calendarEventPropsClientId,
      AppLocalizations.of(context)!.status,
      AppLocalizations.of(context)!.calendarEventPropsCountOfHumans,
      AppLocalizations.of(context)!.noteHint,
      AppLocalizations.of(context)!.calendarEventPropsDateOfActivity,
      AppLocalizations.of(context)!.phoneHint,
      AppLocalizations.of(context)!.calendarEventPropsExcatDayOfActivity,
      AppLocalizations.of(context)!.calendarEventPropsExpireTime,
    ];
  }

  static String _getTextOfVar(Object element, BuildContext context) {
    String textElement = "";
    if (element is DateTime) {
      textElement =
          DateFormat(Constants.WEEKDAY_YEAR_MONTH_DAY).format(element);
    } else if (element is TimeOfDay) {
      textElement = element.format(context);
    } else {
      textElement = element.toString();
    }
    return textElement;
  }

  static List<String> changes(
      CalendarEvent parent, CalendarEvent child, BuildContext context) {
    final List<String> changes = [];
    final naming = namingOfProps(context);
    parent.props.asMap().forEach((idx, element) {
      if (element == child.props[idx]) return;
      final textPropElement = _getTextOfVar(child.props[idx], context);
      final textElement = _getTextOfVar(element, context);

      changes.add("[${naming[idx]}] $textElement >> $textPropElement");
    });
    return changes;
  }

  @override
  String toString() {
    return """
    $nameOfActivity
    $clientId
    $status
    $note
    """;
  }

  Future<void> delete() async {
    await eventsRef.doc(uid).delete();
  }

  static Future<List<CalendarEvent>> getAllOfList() async {
    final events = await eventsRef.get();
    final List<CalendarEvent> returnEvents = [];
    for (final rawEvent in events.docs) {
      final event = rawEvent.data();
      returnEvents.add(event);
    }
    return returnEvents;
  }

  static Future<Map<DateTime, List<CalendarEvent>>> getEventsByDay() async {
    final events = await eventsRef.get();
    final Map<DateTime, List<CalendarEvent>> returnEvents = {};
    for (final rawEvent in events.docs) {
      final event = rawEvent.data();
      if (returnEvents.containsKey(event.dateOfActivity)) {
        returnEvents[event.dateOfActivity]!.add(event);
        continue;
      }
      returnEvents[event.dateOfActivity] = [];
      returnEvents[event.dateOfActivity]!.add(event);
    }
    return returnEvents;
  }

  static Future<CalendarEvent> create(
      String name,
      DateTime dateOfActivity,
      TimeOfDay excatTime,
      TimeOfDay expireTime,
      User user,
      String note,
      StatusesSettings status,
      int countOfHumans,
      String? owner,
      {existsUUID,
      listChanges}) async {
    User? client = await User.find(user);
    if (client == null) {
      await user.save();
    }
    final docId = existsUUID != null ? existsUUID : Uuid().v4();
    final changes = listChanges != null ? listChanges : {};
    final dateOfActivityLocal = DateTime.utc(
        dateOfActivity.year, dateOfActivity.month, dateOfActivity.day);
    return CalendarEvent(
        uid: docId,
        countOfHumans: countOfHumans,
        nameOfActivity: name,
        dateOfActivity: dateOfActivityLocal,
        excatDayOfActivity: excatTime,
        clientId: user.phone,
        numberPhoneOfClient: user.phone,
        status: status,
        expireTime: expireTime,
        listChanges: changes,
        createdAt: dateOfActivity,
        note: note,
        owner: owner);
  }

  Future<void> save() async {
    await eventsRef.doc(uid).set(this);
  }
}
