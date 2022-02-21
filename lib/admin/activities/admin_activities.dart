import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager_activites/admin/statuses/statuses.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:manager_activites/repository/settings.dart';

import 'components/dialog_add.dart';

final settingsRef =
    FirebaseFirestore.instance.collection('settings').doc('general');

class AdminActivitiesViewArguments {
  final bool isAdmin;
  final User user;

  AdminActivitiesViewArguments(this.isAdmin, this.user);
}

class AdminActivitiesView extends StatefulWidget {
  static const route = '/AdminActivitiesView';
  const AdminActivitiesView({Key? key}) : super(key: key);

  @override
  _AdminActivitiesViewState createState() => _AdminActivitiesViewState();
}

class _AdminActivitiesViewState extends State<AdminActivitiesView> {
  final popupItems = ["Manage statuses", "Reset to default"];

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  void dispose() {
    dialogCreatorController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    args = ModalRoute.of(context)!.settings.arguments
        as AdminActivitiesViewArguments;
    setState(() {
      user = args!.user;
      isAdmin = args!.isAdmin;
    });
    super.didChangeDependencies();
  }

  bool loading = true;
  User? user;
  String? displayName;
  bool isAdmin = false;
  List<String> activities = [];
  AdminActivitiesViewArguments? args;
  final dialogCreatorController = TextEditingController();

  Future<void> loadData() async {
    final data = await ActivitiesSettings.blank().getSnapshot();
    setState(() {
      activities = data;
      loading = false;
    });
  }

  _deleteActivity(String deleteActivity) async {
    setState(() {
      activities.remove(deleteActivity);
    });
    await ActivitiesSettings.blank().delete(deleteActivity);
    // Navigator.of(context).pop();
  }

  _tryCreateActivity() async {
    if (dialogCreatorController.text.trim().length > 0) {
      setState(() {
        activities.add(dialogCreatorController.text.trim());
      });
      await ActivitiesSettings.blank()
          .add(ActivitiesSettings(dialogCreatorController.text.trim()));
    }
  }

  _handlePopupMenu(String? value) {
    if (value != null) {
      switch (value) {
        case "Manage statuses":
          Navigator.of(context).pushNamed(AdminStatusesView.route);
          break;
        default:
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.appName),
          actions: [
            if (isAdmin)
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      // TODO: add activity
                      final result = await showDialog<String>(
                        context: context,
                        barrierDismissible: true,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: DialogActivityCreator(
                              hintText:
                                  AppLocalizations.of(context)!.activityName,
                              textController: dialogCreatorController,
                            ),
                            title: Text(
                                AppLocalizations.of(context)!.activityCreator),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop('OK'),
                                child:
                                    Text(AppLocalizations.of(context)!.create),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop('CANCEL'),
                                child:
                                    Text(AppLocalizations.of(context)!.cancel),
                              )
                            ],
                          );
                        },
                      );
                      if (result == 'OK') await _tryCreateActivity();
                      dialogCreatorController.text = '';
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: _handlePopupMenu,
                    itemBuilder: (BuildContext context) {
                      return popupItems.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  )
                ],
              )
          ],
        ),
        body: Container(
          child: !loading
              ? Container(
                  child: activities.length > 0
                      ? RefreshIndicator(
                          onRefresh: loadData,
                          child: ListView.builder(
                            itemCount: activities.length,
                            itemBuilder: (BuildContext context, idx) {
                              return ListTile(
                                title: Text(activities[idx]),
                                trailing: isAdmin
                                    ? IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () =>
                                            _deleteActivity(activities[idx]),
                                      )
                                    : null,
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(AppLocalizations.of(context)!
                              .pleaseCreateAtLastOneActivity),
                        ),
                )
              : Center(
                  child: CircularProgressIndicator(),
                ),
        ));
  }
}
