import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager_activites/repository/settings.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

final settingsRef =
    FirebaseFirestore.instance.collection('settings').doc('general');

class AdminStatusesView extends StatefulWidget {
  static const route = '/AdminStatusesView';
  const AdminStatusesView({Key? key}) : super(key: key);

  @override
  _AdminStatusesViewState createState() => _AdminStatusesViewState();
}

class _AdminStatusesViewState extends State<AdminStatusesView> {
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

  bool loading = true;
  Map<String, dynamic>? settings;
  List<StatusesSettings> statuses = [];
  final dialogCreatorController = TextEditingController();

  Future<void> loadData() async {
    final data = await StatusesSettings.blank().getSnapshot();
    setState(() {
      statuses = data;
      loading = false;
    });
  }

  _deleteStatus(StatusesSettings deleteStatus) async {
    setState(() {
      statuses.remove(deleteStatus);
    });
    // Navigator.of(context).pop();
    StatusesSettings.blank().delete(deleteStatus);
  }

  _tryCreateStatus() async {
    if (dialogCreatorController.text.trim().length > 0) {
      final newStatus = StatusesSettings(
          dialogCreatorController.text.trim(), pickerColor.value);
      setState(() {
        statuses.add(newStatus);
      });
      newStatus.add(newStatus);
    }
  }

  Color pickerColor = Colors.green;

// ValueChanged<Color> callback
  void changeColor(Color color) {
    print(color);
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.statusesTitle),
          actions: [
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
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  controller: dialogCreatorController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: AppLocalizations.of(context)!
                                        .statusName,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: pickerColor,
                                      onColorChanged: changeColor,
                                      showLabel: true,
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                    // Use Material color picker:
                                    //
                                    // child: MaterialPicker(
                                    //   pickerColor: pickerColor,
                                    //   onColorChanged: changeColor,
                                    //   showLabel: true, // only on portrait mode
                                    // ),
                                    //
                                    // Use Block color picker:
                                    //
                                    // child: BlockPicker(
                                    //   pickerColor: currentColor,
                                    //   onColorChanged: changeColor,
                                    // ),
                                    //
                                    // child: MultipleChoiceBlockPicker(
                                    //   pickerColors: currentColors,
                                    //   onColorsChanged: changeColors,
                                    // ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title:
                              Text(AppLocalizations.of(context)!.statusCreator),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop('OK'),
                              child: Text(AppLocalizations.of(context)!.create),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop('CANCEL'),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            )
                          ],
                        );
                      },
                    );
                    if (result == 'OK') await _tryCreateStatus();
                    dialogCreatorController.text = '';
                  },
                ),
              ],
            )
          ],
        ),
        body: Container(
          child: !loading
              ? Container(
                  child: statuses.length > 0
                      ? RefreshIndicator(
                          onRefresh: loadData,
                          child: ListView.builder(
                            itemCount: statuses.length,
                            itemBuilder: (BuildContext context, idx) {
                              return ListTile(
                                  title: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Color(statuses[idx].color),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Text(statuses[idx].name)),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () =>
                                        _deleteStatus(statuses[idx]),
                                  ));
                            },
                          ),
                        )
                      : Center(
                          child: Text(AppLocalizations.of(context)!
                              .pleaseCreateAtLastOneStatus),
                        ),
                )
              : Center(
                  child: CircularProgressIndicator(),
                ),
        ));
  }
}
