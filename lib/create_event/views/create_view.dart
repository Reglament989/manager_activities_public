import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:manager_activites/constants.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/home/data/event_loader.dart';
import 'package:manager_activites/home/view/home_view.dart';
import 'package:manager_activites/repository/settings.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreateViewArguments {
  final DateTime day;
  final String whoami;
  final CalendarEvent? event;

  CreateViewArguments({required this.day, this.event, required this.whoami});
}

class CreateEventView extends StatefulWidget {
  static const route = "/create";
  const CreateEventView({Key? key}) : super(key: key);

  @override
  _CreateEventViewState createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final _btnController = RoundedLoadingButtonController();
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final countOfHumansController = TextEditingController();
  final noteController = TextEditingController();
  final noteUserController = TextEditingController();

  bool clientIsDeleted = false;

  String? activity;
  StatusesSettings status = StatusesSettings("Created", Colors.green.value);
  List<StatusesSettings> statuses = [];
  List<CalendarChange> changes = [];
  bool loading = true;
  List<String> items = [];
  DateTime dateOfActivity = DateTime.now();
  TimeOfDay excatTime = TimeOfDay.now();
  TimeOfDay expireTime =
      TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: TimeOfDay.now().minute);
  DateTime? dateOfBrihtday;
  List<User> users = [];
  User? user;
  String numberOfPhone = '';
  String? error;
  String? owner;
  List<String>? subNumbers;

  CreateViewArguments? args;
  bool parsedArgs = false;

  static String _displayStringForOption(User option) => option.phone;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    args = ModalRoute.of(context)!.settings.arguments as CreateViewArguments;
    parseArguments();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    countOfHumansController.dispose();
    noteController.dispose();
    noteUserController.dispose();
    super.dispose();
  }

  parseArguments() async {
    if (parsedArgs) {
      return;
    }
    dateOfActivity = args!.day;

    if (args!.event != null) {
      setState(() {});
      final rawUser = await usersRef.doc(args!.event!.clientId).get();
      User? fetchUser = rawUser.data();
      if (fetchUser == null) {
        fetchUser = User(firstName: "Deleted", phone: "Deleted", orders: []);
        clientIsDeleted = true;
      }
      final userSubNumbers = await fetchUser.fetchSubNumbers();
      setState(() {
        status = args!.event!.status;
        changes = args!.event!.listChanges;
        dateOfActivity = args!.event!.dateOfActivity;
        excatTime = args!.event!.excatDayOfActivity;
        expireTime = args!.event!.expireTime;
        noteController.text = args!.event!.note;
        countOfHumansController.text = args!.event!.countOfHumans.toString();
        user = fetchUser;
        subNumbers = userSubNumbers;
        firstNameController.text = user!.firstName;
        lastNameController.text = user!.lastName != null ? user!.lastName! : "";
        activity = args!.event!.nameOfActivity;
        numberOfPhone = args!.event!.numberPhoneOfClient;
        owner = args!.event!.owner;
        noteUserController.text = user!.note ?? "";
        if (user!.email != null) {
          emailController.text = user!.email!;
        }
        if (user!.dateOfBirth != null) {
          dateOfBrihtday = user!.dateOfBirth;
        }
        parsedArgs = true;
      });
    }
  }

  loadData() async {
    List<String> data = await ActivitiesSettings.blank().getSnapshot();
    List<StatusesSettings> statusesl =
        await StatusesSettings.blank().getSnapshot();
    setState(() {
      statuses = statusesl;
      if (status.name == "Created") status = statuses[0];
      items = data;
    });
    final rawUsers = await User.getAllUsers();
    setState(() {
      users = rawUsers;
      statuses = statuses;
      loading = false;
    });
  }

  _showDatePicker([bool isDateOfBrihtday = false]) async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: dateOfActivity,
        firstDate: DateTime(1950),
        lastDate: DateTime.now().add(Duration(days: 365)));
    if (pickedDate != null) {
      if (isDateOfBrihtday) {
        setState(() {
          dateOfBrihtday = pickedDate;
        });
      } else {
        setState(() {
          dateOfActivity = pickedDate;
        });
      }
    }
  }

  _showTimePicker([bool expire = false]) async {
    final pickedTime =
        await showTimePicker(context: context, initialTime: excatTime);
    if (pickedTime != null) {
      if (expire) {
        setState(() {
          expireTime = pickedTime;
        });
        return;
      } else {
        setState(() {
          excatTime = pickedTime;
          expireTime =
              TimeOfDay(hour: pickedTime.hour + 1, minute: pickedTime.minute);
        });
      }
    }
  }

  _error(String cause) {
    setState(() {
      error = cause;
    });
    _safeResetBtn();
    HapticFeedback.vibrate();
  }

  _safeResetBtn([bool success = false]) {
    if (success) {
      _btnController.success();
      Future.delayed(Duration(milliseconds: 350),
          () => Navigator.of(context).pop('UPDATE'));
    } else {
      _btnController.error();
    }
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _btnController.reset();
      }
    });
  }

  _submitEvent() async {
    if (clientIsDeleted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
            title: Text("Alert"),
            content: Text("You cannot save orders with deleted clients."),
            actions: [
              TextButton(
                  child: Text("OK"), onPressed: Navigator.of(context).pop)
            ]),
      );
      _safeResetBtn();
      return;
    }
    if (activity == null) {
      _error(AppLocalizations.of(context)!.errorDontHaveTypeActivity);
      return;
    }
    if (user == null) {
      if (numberOfPhone.length < 9) {
        _error(AppLocalizations.of(context)!.errorDontHaveNumberPhoneOfClient);
        return;
      }
      if (firstNameController.text.length < 1) {
        _error(AppLocalizations.of(context)!.errorDontHaveFirstNameOfClient);
        return;
      }
      user = User(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          email: emailController.text.trim(),
          phone: numberOfPhone,
          dateOfBirth: dateOfBrihtday,
          note: noteUserController.text.trim(),
          orders: []);
    }
    if (int.tryParse(countOfHumansController.text) != null) {
      if (countOfHumansController.text.length < 1) {
        _error(
            AppLocalizations.of(context)!.errorDontHaveCountOfHumansOnActivity);
        return;
      }
    } else {
      _error("Count of humans must be round int");
      return;
    }

    user = User(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phone: user!.phone,
      dateOfBirth: dateOfBrihtday,
      note: noteUserController.text.trim(),
      orders: user!.orders,
    );
    if (subNumbers != null) {
      for (final number in subNumbers!) {
        await user!.addSubNumberPhone(number);
      }
    }

    final String currentChanges = "";
    final testEvent = await CalendarEvent.create(
      activity!,
      dateOfActivity,
      excatTime,
      expireTime,
      user!,
      noteController.text.trim(),
      status,
      int.tryParse(countOfHumansController.text)!,
      args!.whoami,
      existsUUID: args?.event?.uid,
      listChanges: changes,
    );
    if (args!.event != null) {
      CalendarEvent.changes(args!.event!, testEvent, context)
          .forEach((element) {
        changes.add(CalendarChange(element,
            FirebaseAuth.instance.currentUser!.email!, DateTime.now()));
      });
    }
    if (currentChanges.length > 0) {
      final endedEvent = await CalendarEvent.create(
          activity!,
          dateOfActivity,
          excatTime,
          expireTime,
          user!,
          noteController.text.trim(),
          status,
          int.tryParse(countOfHumansController.text)!,
          args!.whoami,
          existsUUID: args?.event?.uid,
          listChanges: changes);
      await endedEvent.save();
    } else {
      await testEvent.save();
    }
    _safeResetBtn(true);
  }

  _clearUser() {
    user = null;
    numberOfPhone = '';
    firstNameController.text = '';
    lastNameController.text = '';
    emailController.text = '';
    dateOfBrihtday = null;
  }

  _showAddSubNumberDialog() async {
    final response = await showDialog(
        context: context,
        builder: (BuildContext context) => DialogAddSubNumber());
    if (response != null) {
      setState(() {
        if (subNumbers == null) {
          subNumbers = [];
        }
        subNumbers!.add(response);
      });
    }
  }

  _deleteSubNumber(String number) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => AreYouSureDialog(
            content: AppLocalizations.of(context)!.deleteThisSubnumber(number),
            yesOnPressed: () async {
              setState(() {
                subNumbers!.remove(number);
              });
              await user?.deleteSubNumber(number);
              Navigator.of(context).pop();
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(args!.event != null
            ? AppLocalizations.of(context)!.eventEditingTitle
            : AppLocalizations.of(context)!.createEventTitle),
        actions: [
          IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => Changes(
                      changes: changes,
                      reminderTitle:
                          "Check out details of $activity on ${DateFormat(Constants.WEEKDAY_YEAR_MONTH_DAY).format(dateOfActivity)}"))),
              icon: Icon(Icons.label_important_outline)),
          IconButton(
              onPressed: _showAddSubNumberDialog,
              icon: Icon(
                Icons.add_ic_call,
              ))
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: loading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                physics: !kIsWeb ? BouncingScrollPhysics() : null,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: DropdownSearch<String>(
                        selectedItem: activity,
                        mode: Mode.BOTTOM_SHEET,
                        searchBoxDecoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                            prefixIcon: Icon(Icons.card_travel_outlined)),
                        showSelectedItem: true,
                        items: items,
                        label: AppLocalizations.of(context)!.activityHint,
                        onChanged: (v) {
                          activity = v;
                        }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: _showDatePicker,
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 28,
                              color: Colors.blue,
                            ),
                            Text(
                              DateFormat(
                                      Constants.WEEKDAY_YEAR_MONTH_DAY,
                                      Localizations.localeOf(context)
                                          .languageCode)
                                  .format(dateOfActivity),
                              style: TextStyle(fontSize: 17),
                            )
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _showTimePicker,
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 28,
                              color: Colors.blue,
                            ),
                            Text(
                              excatTime.format(context),
                              style: TextStyle(fontSize: 17),
                            )
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showTimePicker(true),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_off,
                              size: 28,
                              color: Colors.blue,
                            ),
                            Text(
                              expireTime.format(context),
                              style: TextStyle(fontSize: 17),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      child: Autocomplete<User>(
                        displayStringForOption: _displayStringForOption,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<User>.empty();
                          }

                          return users.where((User option) {
                            return option.phone
                                .contains(textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (u) {
                          setState(() {
                            user = u;
                            firstNameController.text = u.firstName;
                            lastNameController.text =
                                u.lastName != null ? u.lastName! : "";
                            dateOfBrihtday = u.dateOfBirth;
                            emailController.text =
                                u.email != null ? u.email! : '';
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController fieldTextEditingController,
                            FocusNode fieldFocusNode,
                            VoidCallback onFieldSubmitted) {
                          // fieldTextEditingController.addListener(() {
                          //
                          // });
                          if (args != null) {
                            if (numberOfPhone.length > 1) {
                              if (fieldTextEditingController.text.length < 1) {
                                fieldTextEditingController.text = numberOfPhone;
                              }
                            }
                          }
                          return TextFormField(
                            keyboardType: TextInputType.phone,
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.phoneHint,
                                border: OutlineInputBorder(),
                                prefixIcon: InkWell(
                                    child: Icon(
                                      Icons.phone,
                                      color: Colors.deepOrange,
                                    ),
                                    onTap: () => launch("tel:$numberOfPhone")),
                                suffixIcon: InkWell(
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.deepOrange,
                                    ),
                                    onTap: () {
                                      _clearUser();
                                      fieldTextEditingController.clear();
                                    })),
                            onChanged: (value) {
                              numberOfPhone = value;
                            },
                          );
                        },
                      )),
                  if (subNumbers != null && subNumbers!.length > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        title: Text(
                            AppLocalizations.of(context)!.extraNumberPhones),
                        children: subNumbers!
                            .map((e) => ListTile(
                                title: Text(e),
                                onTap: () => launch("tel:$e"),
                                onLongPress: () => _deleteSubNumber(e)))
                            .toList(),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            controller: firstNameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.firstNameHint,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextFormField(
                            controller: lastNameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context)!.lastNameHint,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  ExpansionTile(
                    title: Text(AppLocalizations.of(context)!.extraOptions),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 16, left: 16, bottom: 16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, bottom: 16),
                              child: InkWell(
                                onTap: () => _showDatePicker(true),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cake,
                                      size: 28,
                                      color: Colors.red,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(AppLocalizations.of(context)!
                                          .dateOfBirthday),
                                    ),
                                    Text(
                                      dateOfBrihtday != null
                                          ? DateFormat(Constants
                                                  .WEEKDAY_YEAR_MONTH_DAY)
                                              .format(dateOfBrihtday!)
                                          : '???',
                                      style: TextStyle(fontSize: 17),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                  hintText:
                                      AppLocalizations.of(context)!.emailHint,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.alternate_email)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: TextFormField(
                                textCapitalization:
                                    TextCapitalization.sentences,
                                maxLines: 3,
                                controller: noteUserController,
                                decoration: InputDecoration(
                                    hintText:
                                        AppLocalizations.of(context)!.noteHint,
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.edit)),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  TextFormField(
                    controller: countOfHumansController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context)!.countOfHumansHint,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.face)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: DropdownSearch<StatusesSettings>(
                        itemAsString: (s) => s.name,
                        compareFn: (item, selectedItem) =>
                            item.name == selectedItem?.name,
                        selectedItem: status,
                        mode: Mode.BOTTOM_SHEET,
                        searchBoxDecoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                            prefixIcon: Icon(Icons.card_travel_outlined)),
                        showSelectedItem: true,
                        items: statuses,
                        label: AppLocalizations.of(context)!.status,
                        onChanged: (v) {
                          if (v != null && v != status) {
                            setState(() {
                              status = v;
                            });
                          }
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 8),
                    child: TextFormField(
                      controller: noteController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines:
                          6, // any number you need (It works as the rows for the textarea)
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.noteHint,
                          border: OutlineInputBorder()),
                    ),
                  ),
                  error != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(15)),
                            padding: EdgeInsets.all(28),
                            child: Center(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Icon(Icons.error),
                                ),
                                Text(error!)
                              ],
                            )),
                          ),
                        )
                      : SizedBox(),
                  if (owner != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8, bottom: 16, right: 8),
                      child: Text(
                        AppLocalizations.of(context)!.activityOwner(owner!),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  RoundedLoadingButton(
                      controller: _btnController,
                      onPressed: _submitEvent,
                      child: Text(AppLocalizations.of(context)!.submitButton))
                ],
              ),
      ),
    );
  }
}

class DialogAddSubNumber extends StatefulWidget {
  const DialogAddSubNumber({Key? key}) : super(key: key);

  @override
  _DialogAddSubNumberState createState() => _DialogAddSubNumberState();
}

class _DialogAddSubNumberState extends State<DialogAddSubNumber> {
  final textController = TextEditingController();

  _push() async {
    Navigator.of(context).pop(textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addSubNumber),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel)),
        TextButton(
            onPressed: _push,
            child: Text(AppLocalizations.of(context)!.create)),
      ],
      content: Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
              controller: textController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.phoneHint,
                  border: OutlineInputBorder()))),
    );
  }
}

class Changes extends StatefulWidget {
  const Changes({Key? key, required this.changes, required this.reminderTitle})
      : super(key: key);
  final List<CalendarChange> changes;
  final String reminderTitle;

  @override
  _ChangesState createState() => _ChangesState();
}

class _ChangesState extends State<Changes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.changesTitle),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext ctx) => ReminderDialog(
                          reminderTitle: widget.reminderTitle,
                        ));
              },
              icon: Icon(Icons.notification_add))
        ],
      ),
      body: widget.changes.length > 0
          ? ListView.builder(
              itemCount: widget.changes.length,
              itemBuilder: (BuildContext context, idx) {
                DateTime date = widget.changes[idx].whenCommitted;
                return ListTile(
                    title: Text(widget.changes[idx].change),
                    subtitle: Text(widget.changes[idx].whoCommitted),
                    trailing: Text(DateFormat(Constants.WEEKDAY_YEAR_MONTH_DAY,
                            Localizations.localeOf(context).languageCode)
                        .format(date)));
              },
            )
          : Center(
              child: Text(
                  AppLocalizations.of(context)!.currentlyNoHaveChangesTitle)),
    );
  }
}

class ReminderDialog extends StatefulWidget {
  const ReminderDialog({Key? key, required this.reminderTitle})
      : super(key: key);
  final String reminderTitle;

  @override
  _ReminderDialogState createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  DateTime dateOfRemind = DateTime.now();
  TimeOfDay timeOfRemind = TimeOfDay.now();
  final textController = TextEditingController();

  _showDatePicker(BuildContext ctx) async {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final pickedDate = await showDatePicker(
      context: ctx,
      initialDate: dateOfRemind,
      firstDate: DateTime.now(),
      lastDate: lastDayOfMonth,
    );

    if (pickedDate != null) {
      setState(() {
        dateOfRemind = pickedDate;
      });
    }
  }

  _showTimePicker(BuildContext ctx) async {
    final pickedTime =
        await showTimePicker(context: context, initialTime: timeOfRemind);
    if (pickedTime != null &&
        pickedTime.hour >= TimeOfDay.now().hour &&
        pickedTime.minute > TimeOfDay.now().minute) {
      setState(() {
        timeOfRemind = pickedTime;
      });
    }
  }

  _submitRemind() async {
    final remindersRef = FirebaseFirestore.instance.collection("reminders");
    await remindersRef.add({
      'title': 'Reminder',
      'body': textController.text.trim() == ""
          ? widget.reminderTitle
          : textController.text.trim(),
      'hour': timeOfRemind.hour.toString(),
      'minute': timeOfRemind.minute.toString(),
      'day': dateOfRemind.day.toString(),
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add new reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
                child: Text(DateFormat(Constants.WEEKDAY_YEAR_MONTH_DAY,
                        Localizations.localeOf(context).languageCode)
                    .format(dateOfRemind)),
                onPressed: () => _showDatePicker(context)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
                child: Text(timeOfRemind.format(context)),
                onPressed: () => _showTimePicker(context)),
          ),
          TextField(
              controller: textController,
              decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.noteHint,
                  border: OutlineInputBorder())),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _submitRemind,
            child: Text(AppLocalizations.of(context)!.submitButton)),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel))
      ],
    );
  }
}
