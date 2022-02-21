import 'package:flutter/material.dart';
import 'package:manager_activites/home/data/event_loader.dart';
import 'package:manager_activites/home/home.dart';
import 'package:manager_activites/repository/settings.dart';

class AllActivitiesView extends StatefulWidget {
  static const route = "/AllActivitiesView";
  const AllActivitiesView({Key? key}) : super(key: key);

  @override
  _AllActivitiesViewState createState() => _AllActivitiesViewState();
}

class _AllActivitiesViewState extends State<AllActivitiesView> {
  List<CalendarEvent>? _events;
  List<StatusesSettings>? statuses;
  bool loading = true;
  String filter = "";
  String? statusFilter;

  Iterable<CalendarEvent> get events {
    Iterable<CalendarEvent>? list = _events!
        .where((f) => f.toString().toLowerCase().contains(RegExp(filter)));
    if (statusFilter != null) {
      list =
          list.where((f) => f.toString().toLowerCase().contains(statusFilter!));
    }
    return list;
  }

  loadData() async {
    final localEvents = await CalendarEvent.getAllOfList();
    final statusesl = await StatusesSettings.blank().getSnapshot();
    statusesl.add(StatusesSettings("All", 0));
    setState(() {
      _events = localEvents;
      statuses = statusesl;
      loading = false;
    });
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  _showStatusPicker() async {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: SingleChildScrollView(
                  child: Wrap(
                children: List<Widget>.generate(
                  statuses!.length,
                  (idx) => ListTile(
                    onTap: () {
                      setState(() {
                        if (statuses![idx].name == "All")
                          statusFilter = "";
                        else
                          statusFilter = statuses![idx].name.toLowerCase();
                      });
                      Navigator.of(context).pop();
                    },
                    title: Text(statuses![idx].name),
                  ),
                ),
              )),
            ));
  }

  _handlePopupMenu(value) {
    switch (value) {
      case "sortByStatus":
        _showStatusPicker();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 15,
          ),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: TextFormField(
            onChanged: (value) => setState(() {
              filter = value.toLowerCase();
            }),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 1),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handlePopupMenu,
            itemBuilder: (BuildContext context) {
              return <PopupMenuItem<String>>[
                PopupMenuItem(
                  value: 'sortByStatus',
                  child: Text('By status'),
                )
              ];
            },
          )
        ],
      ),
      body: Container(
        child: loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: events.length,
                itemBuilder: (BuildContext context, idx) {
                  return CalendarEventListTile(
                    currentEvent: events.elementAt(idx),
                    selectedDay: DateTime.now(),
                    showWithDate: true,
                  );
                },
              ),
      ),
    );
  }
}
