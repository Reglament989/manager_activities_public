import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/create_event/views/create_view.dart';
import 'package:manager_activites/home/view/home_view.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

import '../../constants.dart';

class ContactCreateViewArguments {
  final User contact;

  ContactCreateViewArguments(this.contact);
}

class ContactCreateView extends StatefulWidget {
  static const route = "/ContactCreateView/mega/puper";
  const ContactCreateView({Key? key}) : super(key: key);

  @override
  _ContactCreateViewState createState() => _ContactCreateViewState();
}

class _ContactCreateViewState extends State<ContactCreateView> {
  final _btnController = RoundedLoadingButtonController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final noteController = TextEditingController();
  DateTime? dateOfBrihtday;
  String? error;
  List<String>? subNumbers;
  bool loaded = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  didChangeDependencies() {
    if (!loaded) {
      setState(() {
        final args = ModalRoute.of(context)!.settings.arguments
            as ContactCreateViewArguments?;
        if (args != null) {
          _fromContact(args);
        }
      });
    }
    super.didChangeDependencies();
  }

  _fromContact(ContactCreateViewArguments args) {
    emailController.text = args.contact.email ?? "";
    firstNameController.text = args.contact.firstName;
    lastNameController.text = args.contact.lastName ?? "";
    phoneController.text = args.contact.phone;
    noteController.text = args.contact.note ?? "";
  }

  _showDatePicker() async {
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now().add(Duration(days: 365)));
    if (pickedDate != null) {
      setState(() {
        dateOfBrihtday = pickedDate;
      });
    }
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

  _createClient() async {
    if (firstNameController.text.trim().length > 2 &&
        firstNameController.text.trim().length > 2 &&
        phoneController.text.trim().length >= 10) {
      if (phoneController.text.trim().length > 15 ||
          firstNameController.text.trim().length > 15 ||
          firstNameController.text.trim().length > 15) {
        setState(() {
          error = "Please check correctness of data.";
        });
        return;
      }

      final user = User(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          orders: [],
          phone: phoneController.text.trim(),
          note: noteController.text.trim());
      await user.save();
      if (subNumbers != null) {
        for (final number in subNumbers!) {
          await user.addSubNumberPhone(number);
        }
      }
      _safeResetBtn(true);
    } else {
      setState(() {
        error = "Please check correctness of data.";
      });
      _safeResetBtn();
    }
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

  _deleteSubNumber(String number) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AreYouSureDialog(
            content: AppLocalizations.of(context)!.deleteThisSubnumber(number),
            yesOnPressed: () {
              setState(() {
                subNumbers!.remove(number);
                Navigator.of(context).pop();
              });
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.createClientTitle),
          actions: [
            IconButton(
                onPressed: _showAddSubNumberDialog,
                icon: Icon(
                  Icons.add_ic_call,
                ))
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    controller: firstNameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.firstNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    textCapitalization: TextCapitalization.sentences,
                    controller: lastNameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.lastNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    keyboardType: TextInputType.phone,
                    controller: phoneController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.phoneHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
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
                              onTap: () => _showDatePicker(),
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
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 3,
                              controller: noteController,
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
                if (error != null)
                  Padding(
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.error),
                          ),
                          Text(error!)
                        ],
                      )),
                    ),
                  ),
                if (subNumbers != null && subNumbers!.length > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title:
                          Text(AppLocalizations.of(context)!.extraNumberPhones),
                      children: subNumbers!
                          .map((e) => ListTile(
                              title: Text(e),
                              onLongPress: () => _deleteSubNumber(e)))
                          .toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RoundedLoadingButton(
                      controller: _btnController,
                      onPressed: _createClient,
                      child: Text(AppLocalizations.of(context)!.submitButton)),
                )
              ],
            ),
          ),
        ));
  }
}
