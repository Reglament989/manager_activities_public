import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager_activites/contacts/views/make_new.dart';
import 'package:manager_activites/create_event/create_event.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/home/data/event_loader.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final eventsRef = FirebaseFirestore.instance.collection('events');

class DetailContactViewArguments {
  User user;
  final String whoami;

  DetailContactViewArguments(this.user, this.whoami);
}

class DetailContactView extends StatefulWidget {
  static const route = "/contact/details";
  const DetailContactView({Key? key}) : super(key: key);

  @override
  _DetailContactViewState createState() => _DetailContactViewState();
}

class _DetailContactViewState extends State<DetailContactView> {
  DetailContactViewArguments? args;
  bool isArgsSetted = false;
  List<CalendarEvent> events = [];
  bool loading = true;
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  List<String> popupItems = [];

  @override
  void didChangeDependencies() {
    if (isArgsSetted) {
      return;
    }
    args = ModalRoute.of(context)!.settings.arguments
        as DetailContactViewArguments;
    _loadEvents();
    popupItems = [AppLocalizations.of(context)!.clientEdit];
    isArgsSetted = true;
    super.didChangeDependencies();
  }

  Future<void> _loadEvents() async {
    final rawEvents =
        await eventsRef.where('clientId', isEqualTo: args!.user.phone).get();
    final List<CalendarEvent> newEvents = [];
    for (final rawEvent in rawEvents.docs) {
      newEvents.add(CalendarEvent.fromJson(rawEvent.data()));
    }
    final userUpdate = await args!.user.sync();

    setState(() {
      events = newEvents;
      loading = false;
      if (userUpdate != null) args!.user = userUpdate;
    });
    // debugPrint(events.length.toString());
  }

  _openEventPage(idx) async {
    await Navigator.of(context).pushReplacementNamed(CreateEventView.route,
        arguments: CreateViewArguments(
            event: events[idx],
            day: events[idx].dateOfActivity,
            whoami: args!.whoami));
    refreshKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.contactPageTemplate(
              args!.user.firstName, args!.user.lastName ?? "")),
          actions: [
            PopupMenuButton(
                onSelected: (_) async {
                  await Navigator.of(context).pushNamed(ContactCreateView.route,
                      arguments: ContactCreateViewArguments(args!.user));
                  await refreshKey.currentState?.show();
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                itemBuilder: (BuildContext context) => popupItems
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.cyan,
                              ),
                              Text(e)
                            ],
                          ),
                        ))
                    .toList())
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).pushNamed(
              CreateEventView.route,
              arguments: CreateViewArguments(
                  day: DateTime.now(), whoami: args!.whoami)),
          child: Icon(Icons.plus_one),
        ),
        body: !loading
            ? RefreshIndicator(
                key: refreshKey,
                onRefresh: _loadEvents,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: args!.user
                              .props(context)
                              .map((e) => ListTile(title: Text(e)))
                              .toList(),
                        ),
                      ),
                      flex: 0,
                    ),
                    Expanded(
                      child: Container(
                        child: events.length > 0
                            ? ListView.builder(
                                itemCount: events.length,
                                itemBuilder: (BuildContext context, idx) =>
                                    ListTile(
                                  onTap: () async => _openEventPage(idx),
                                  title: Text('${events[idx].nameOfActivity}'),
                                  subtitle: Text(
                                      '${DateFormat(DateFormat.YEAR_MONTH_DAY).format(events[idx].dateOfActivity)}'),
                                  trailing: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Color(events[idx].status.color),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(events[idx].status.name),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(AppLocalizations.of(context)!
                                    .thisClientDoesNotHaveOrders),
                              ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(child: CircularProgressIndicator()));
  }
}
