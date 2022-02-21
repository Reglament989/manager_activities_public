import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:manager_activites/constants.dart';
import 'package:manager_activites/contacts/views/contacts_view.dart';
import 'package:manager_activites/contacts/views/make_new.dart';
import 'package:manager_activites/create_event/create_event.dart';
import 'package:manager_activites/home/data/event_loader.dart';
import 'package:manager_activites/home/view/all_activities_view.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:manager_activites/self_updater/self_updater.dart';
import 'package:manager_activites/settings/views/settings_view.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

/// {@template counter_view}
/// A [StatelessWidget] which reacts to the provided
/// [CounterCubit] state and notifies it in response to user input.
/// {@endtemplate}
class HomeView extends StatefulWidget {
  static const route = '/home';
  HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewWrapperState createState() => _HomeViewWrapperState();
}

class _HomeViewWrapperState extends State<HomeView> {
  Map<String, dynamic>? popupItems;

  int _currentIndex = 0;
  String appTitleBar = "";
  final PageController _pageController = PageController();
  final refreshContactsListKey = GlobalKey<RefreshIndicatorState>();
  List<CalendarEvent>? currentEvent;
  Map<DateTime, List<CalendarEvent>>? events;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool loading = true;

  @override
  void didChangeDependencies() {
    if (popupItems == null)
      popupItems = {
        'newContact': {
          'text': AppLocalizations.of(context)!.addNewContactButton,
          'icon': Icons.contacts,
        },
        // 'help': AppLocalizations.of(context)!.help
      };
    appTitleBar = AppLocalizations.of(context)!.appName;
    super.didChangeDependencies();
  }

  checkUpdates() async {
    if (!kIsWeb) {
      final update = await Updater.getFromGitHub();
      if (update != null) {
        Updater.showUpdateDialog(context, update);
      }
    }
  }

  @override
  void initState() {
    checkUpdates();
    final Stream<QuerySnapshot> _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .orderBy("excatDayOfActivity")
        .snapshots(includeMetadataChanges: true);
    _eventsStream.listen((event) {
      // print('Update state');
      final Map<DateTime, List<CalendarEvent>> returnEvents = {};
      for (final rawEvent in event.docs) {
        final event = CalendarEvent.fromJson(rawEvent.data());
        if (returnEvents.containsKey(event.dateOfActivity)) {
          returnEvents[event.dateOfActivity]!.add(event);
          continue;
        }
        returnEvents[event.dateOfActivity] = [];
        returnEvents[event.dateOfActivity]!.add(event);
      }
      _selectedDay =
          DateTime.utc(_focusedDay.year, _focusedDay.month, _focusedDay.day);
      if (mounted) {
        setState(() {
          events = returnEvents;
          currentEvent = getEventsByDay(_selectedDay!);
        });
        if (loading) {
          setState(() {
            loading = false;
          });
        }
      } else {
        events = returnEvents;
        currentEvent = getEventsByDay(_selectedDay!);
        if (loading) {
          loading = false;
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<CalendarEvent> getEventsByDay(DateTime day) {
    if (events!.containsKey(day)) {
      return events![day]!;
    }
    return [];
  }

  _handlePopupMenu(String? value) async {
    if (value != null) {
      switch (value) {
        case "newContact":
          final resp =
              await Navigator.of(context).pushNamed(ContactCreateView.route);
          if (resp == "UPDATE") {
            refreshContactsListKey.currentState?.show();
          }
          break;
        case "goToAllActivities":
          Navigator.of(context).pushNamed(AllActivitiesView.route);
          break;
        default:
      }
    }
  }

  _changePage(index) {
    String title = AppLocalizations.of(context)!.appName;
    switch (index) {
      case 1:
        title = AppLocalizations.of(context)!.contactsBottomItem;
        break;
      case 2:
        title = AppLocalizations.of(context)!.settingsBottomItem;
        break;
      default:
    }
    setState(() {
      _currentIndex = index;
      appTitleBar = title;
    });
  }

  _showDeleteAlertForEvent(CalendarEvent event) {
    showDialog(
        context: context,
        builder: (_) => AreYouSureDialog(
            content: AppLocalizations.of(context)!.areYouSure(
                event.nameOfActivity, event.excatDayOfActivity.format(context)),
            yesOnPressed: () {
              event.delete();
              Navigator.of(context).pop();
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appTitleBar,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          Visibility(
            visible: _currentIndex == 1,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onSelected: _handlePopupMenu,
              itemBuilder: (BuildContext context) {
                final List<PopupMenuItem<String>> items = [];
                popupItems!.forEach((String value, dynamic choice) {
                  items.add(PopupMenuItem<String>(
                    value: value,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(
                          choice['icon'],
                          color: Colors.cyan,
                        ),
                        Text(choice['text']),
                      ],
                    ),
                  ));
                });
                return items;
              },
            ),
          ),
          Visibility(
            visible: _currentIndex == 0,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              onSelected: _handlePopupMenu,
              itemBuilder: (BuildContext context) {
                return <PopupMenuItem<String>>[
                  PopupMenuItem(
                    value: 'goToAllActivities',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(Icons.select_all, color: Colors.cyan),
                        Text(
                            AppLocalizations.of(context)!.settingsAllActivities)
                      ],
                    ),
                  )
                ];
              },
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox.expand(
              child: PageView(
                controller: _pageController,
                onPageChanged: _changePage,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TableCalendar(
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              locale:
                                  Localizations.localeOf(context).languageCode,
                              calendarFormat: _calendarFormat,
                              firstDay: DateTime.utc(2020, 10, 16),
                              lastDay: DateTime.utc(2022, 12, 16),
                              // rowHeight: 56,
                              shouldFillViewport: true,
                              focusedDay: _focusedDay,
                              headerStyle:
                                  HeaderStyle(formatButtonVisible: false),
                              calendarStyle: !kIsWeb
                                  ? CalendarStyle(markersAnchor: -0.3)
                                  : CalendarStyle(),
                              onDayLongPressed: (day, focused) {
                                Navigator.of(context)
                                    .pushNamed(CreateEventView.route,
                                        arguments: CreateViewArguments(
                                          day: day,
                                          whoami: Provider.of<UserRepository>(
                                                  context,
                                                  listen: false)
                                              .user!
                                              .email!,
                                        ));
                              },
                              onDaySelected: (selected, focused) {
                                if (!isSameDay(_selectedDay, selected)) {
                                  // Call `setState()` when updating the selected day
                                  setState(() {
                                    currentEvent = getEventsByDay(selected);
                                    _selectedDay = selected;
                                    _focusedDay = focused;
                                  });
                                }
                              },
                              selectedDayPredicate: (day) {
                                // Use `selectedDayPredicate` to determine which day is currently selected.
                                // If this returns true, then `day` will be marked as selected.

                                // Using `isSameDay` is recommended to disregard
                                // the time-part of compared DateTime objects.
                                // if (!isSameDay(_selectedDay, day)) {
                                //
                                // }
                                return isSameDay(_selectedDay, day);
                              },
                              eventLoader: getEventsByDay,
                              onPageChanged: (focusedDay) {
                                // No need to call `setState()` here
                                _focusedDay = focusedDay;
                              },
                            ),
                          ),
                          Divider(),
                          if (currentEvent != null && currentEvent!.length > 0)
                            Expanded(
                              // height: 230,
                              child: ListView.builder(
                                physics: BouncingScrollPhysics(),
                                itemCount: currentEvent!.length,
                                itemBuilder: (BuildContext context, idx) =>
                                    CalendarEventListTile(
                                        showDeleteAlertForEvent:
                                            _showDeleteAlertForEvent,
                                        currentEvent: currentEvent![idx],
                                        selectedDay: _selectedDay),
                              ),
                            )
                          else
                            Expanded(
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                          CreateEventView.route,
                                          arguments: CreateViewArguments(
                                              whoami:
                                                  Provider.of<UserRepository>(
                                                          context,
                                                          listen: false)
                                                      .user!
                                                      .email!,
                                              day: _selectedDay!));
                                    },
                                    child: Text(AppLocalizations.of(context)!
                                        .createEventTitle),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 62),
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(12)),
                                        )),
                                  ),
                                ),
                              ),
                            )
                        ],
                      )),
                  Container(
                    child: ContactsView(
                      refreshKey: refreshContactsListKey,
                    ),
                  ),
                  Container(
                    child: const SettingsView(),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavyBar(
        items: [
          BottomNavyBarItem(
              icon: const Icon(Icons.calendar_today),
              title: Text(AppLocalizations.of(context)!.calendarBottomItem)),
          BottomNavyBarItem(
              icon: const Icon(Icons.contacts),
              title: Text(AppLocalizations.of(context)!.contactsBottomItem)),
          BottomNavyBarItem(
              icon: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settingsBottomItem)),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(index,
              duration: Duration(milliseconds: 300), curve: Curves.ease);
        },
      ),
    );
  }
}

class CalendarEventListTile extends StatelessWidget {
  const CalendarEventListTile(
      {Key? key,
      required this.currentEvent,
      required DateTime? selectedDay,
      this.showWithDate = false,
      this.showDeleteAlertForEvent})
      : _selectedDay = selectedDay,
        super(key: key);

  final CalendarEvent currentEvent;
  final DateTime? _selectedDay;
  final void Function(CalendarEvent)? showDeleteAlertForEvent;
  final bool showWithDate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(currentEvent.nameOfActivity),
      subtitle: showWithDate
          ? Text(DateFormat(Constants.WEEKDAY_YEAR_MONTH_DAY)
              .format(currentEvent.dateOfActivity))
          : null,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(currentEvent.excatDayOfActivity.format(context)),
            Text(currentEvent.expireTime.format(context))
          ],
        ),
      ),
      trailing: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Color(currentEvent.status.color),
              borderRadius: BorderRadius.circular(8)),
          child: Text(currentEvent.status.name)),
      onLongPress: () => showDeleteAlertForEvent != null
          ? showDeleteAlertForEvent!(currentEvent)
          : null,
      onTap: () {
        Navigator.of(context).pushNamed(CreateEventView.route,
            arguments: CreateViewArguments(
              day: _selectedDay!,
              event: currentEvent,
              whoami: Provider.of<UserRepository>(context, listen: false)
                  .user!
                  .email!,
            ));
      },
    );
  }
}

class AreYouSureDialog extends StatelessWidget {
  const AreYouSureDialog(
      {Key? key, required this.content, required this.yesOnPressed})
      : super(key: key);
  final String content;
  final void Function() yesOnPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(AppLocalizations.of(context)!.delete),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: yesOnPressed,
              child: Text(AppLocalizations.of(context)!.yes)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.no)),
        ]);
  }
}
