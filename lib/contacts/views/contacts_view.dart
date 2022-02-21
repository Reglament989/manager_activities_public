import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:manager_activites/contacts/views/detailed_contact.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:provider/provider.dart';

class ContactsView extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState> refreshKey;
  ContactsView({Key? key, required this.refreshKey}) : super(key: key);

  @override
  _ContactsViewState createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView>
    with AutomaticKeepAliveClientMixin<ContactsView> {
  bool loading = true;
  bool argsParsed = false;
  String filter = '';
  List<User>? _contacts;

  List<User> get contacts =>
      _contacts!.where((f) => f.toString().contains(RegExp(filter))).toList();

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  Future<void> loadData() async {
    final localContacts = await User.getAllUsers();
    for (final contact in localContacts) {
      await contact.fetchSubNumbers();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _contacts = localContacts;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return loading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CupertinoSearchTextField(
                  placeholder: AppLocalizations.of(context)!.search,
                  onChanged: (String value) {
                    // print('The text has changed to: $value');
                    setState(() {
                      filter = value;
                    });
                  },
                ),
              ),
              if (_contacts!.length > 0)
                Expanded(
                  child: Container(
                    child: RefreshIndicator(
                      key: widget.refreshKey,
                      onRefresh: loadData,
                      child: ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (BuildContext context, idx) {
                          return ListTile(
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(DetailContactView.route,
                                      arguments: DetailContactViewArguments(
                                        contacts[idx],
                                        Provider.of<UserRepository>(context,
                                                listen: false)
                                            .user!
                                            .email!,
                                      ));
                              widget.refreshKey.currentState?.show();
                            },
                            onLongPress: () {
                              showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .confirmDeleteClientTitle),
                                        content: Text(
                                            AppLocalizations.of(context)!
                                                .confirmDeleteClientContent),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                contacts[idx].delete();
                                                Navigator.of(context).pop();
                                                widget.refreshKey.currentState!
                                                    .show();
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .buttonWithConfirm))
                                        ],
                                      ));
                            },
                            title: Text(contacts[idx].firstName),
                            subtitle: Text(contacts[idx].phone),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                Center(
                    child:
                        Text(AppLocalizations.of(context)!.youDontHaveContacts))
            ],
          );
  }
}
