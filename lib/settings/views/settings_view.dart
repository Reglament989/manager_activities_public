import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:manager_activites/admin/activities/admin_activities.dart';
import 'package:manager_activites/create_event/data/users.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:manager_activites/self_updater/self_updater.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xml/xml.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  exportToJson({asYaml = false}) async {
    final rawUsers = (await User.getAllUsers()).map((e) => e.toJson()).toList();
    final spaces = ' ' * 4;
    final encoder = JsonEncoder.withIndent(spaces);
    final yaml = encoder.convert(rawUsers);
    final String? tmpFile;
    if (asYaml) {
      tmpFile = (await getTemporaryDirectory()).path + "/clients.yaml";
    } else {
      tmpFile = (await getTemporaryDirectory()).path + "/clients.json";
    }
    final file = await File(tmpFile).writeAsString(yaml);
    await Share.shareFiles([file.path]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UserRepository>();
    return Container(
      child: Column(
        children: [
          const Icon(Icons.person, size: 84),
          Text(
            provider.user!.email!,
            style: TextStyle(fontSize: 18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.settingsAllActivities),
                    onTap: () {
                      Navigator.of(context).pushNamed(AdminActivitiesView.route,
                          arguments: AdminActivitiesViewArguments(
                              provider.isAdmin, provider.user!));
                    },
                  ),
                  ListTile(
                    title: Text(
                        AppLocalizations.of(context)!.settingsChangeUsername),
                  ),
                  ListTile(
                    title: Text(AppLocalizations.of(context)!.settingsAboutApp),
                    onTap: () async {
                      final version = await Updater.getVersion();
                      showAboutDialog(
                          context: context,
                          applicationName: "Metricia",
                          applicationIcon: Image.asset(
                            "assets/launcher_icon.png",
                            width: 64,
                            height: 64,
                          ),
                          applicationVersion: version);
                    },
                  ),
                  if (!kIsWeb)
                    if (Platform.isAndroid)
                      ListTile(
                          title: Text(AppLocalizations.of(context)!
                              .settingsCheckUpdates),
                          onTap: () async {
                            final update = await Updater.getFromGitHub();
                            if (update != null) {
                              Updater.showUpdateDialog(context, update);
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!
                                    .settingsUpdatesNotFound),
                              ));
                            }
                          }),
                  if (provider.isAdmin)
                    ListTile(
                      title: Text(AppLocalizations.of(context)!
                          .settingsExportContactsBtn),
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                                  title: Text(AppLocalizations.of(context)!
                                      .exportContactsTitle),
                                  content: Text(AppLocalizations.of(context)!
                                      .exportContactsContent),
                                  actions: [
                                    TextButton(
                                      child: const Text('XML'),
                                      onPressed: () async {
                                        // TODO: to xml export and share file
                                        final rawUsers =
                                            await User.getAllUsers();
                                        final builder = XmlBuilder();
                                        // final dialog = showDialog(
                                        //     context: context,
                                        //     builder: (_) =>
                                        //         AlertDialog(content: LinearProgressIndicator(value: ,),));
                                        builder.processing(
                                            "xml", 'version="1.0"');
                                        rawUsers.forEach((u) {
                                          builder.buildUser(u);
                                        });
                                        final document =
                                            builder.buildDocument();
                                        final tmpFile =
                                            (await getTemporaryDirectory())
                                                    .path +
                                                "/clients.xml";
                                        final file = await File(tmpFile)
                                            .writeAsString(
                                                document.toXmlString());
                                        await Share.shareFiles([file.path]);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('YAML'),
                                      onPressed: () {
                                        exportToJson(asYaml: true);
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('JSON'),
                                      onPressed: () {
                                        exportToJson();
                                      },
                                    ),
                                  ],
                                ));
                      },
                    ),
                  ListTile(
                    onTap: () =>
                        Provider.of<UserRepository>(context, listen: false)
                            .signOut(),
                    title: Text(
                        AppLocalizations.of(context)!.settingsLogoutButton),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

extension BilderUsers on XmlBuilder {
  void buildUser(User user) {
    element("user", nest: () {
      element("firstName", nest: user.firstName);
      element("lastName", nest: user.lastName);
      element("phone", nest: user.phone);
      element("date_of_birth", nest: user.dateOfBirth?.toIso8601String());
    });
  }
}
