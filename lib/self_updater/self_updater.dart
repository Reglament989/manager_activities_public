import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:open_file/open_file.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../constants.dart';

class Update {
  final String downloadUrl;
  final String newVersion;
  final String? patchNote;

  Update(this.downloadUrl, this.newVersion, this.patchNote);
}

class Updater {
  static Future<Update?> getFromGitHub() async {
    try {
      final json = (await Dio().get('https://api.github.com/repos/Reglament989/manager_activity/releases/latest'))
          .data;
      if (Version.parse(await getVersion()) < Version.parse(json['tag_name']))
        return Update(
            'https://api.github.com/repos/Reglament989/manager_activity/releases/assets/${json['assets'][0]['id']}',
            json['tag_name'],
            json['body']);
      // ignore: empty_catches
    } catch (e) {}
    return null;
  }

  static Future<String> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static showUpdateDialog(BuildContext context, Update update) {
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            DownloadUpdateDialog(update: update));
  }
}

class DownloadUpdateDialog extends StatefulWidget {
  final Update update;
  DownloadUpdateDialog({Key? key, required this.update}) : super(key: key);

  @override
  _DownloadUpdateDialogState createState() => _DownloadUpdateDialogState();
}

class _DownloadUpdateDialogState extends State<DownloadUpdateDialog> {
  bool downloading = false;
  bool finished = false;
  double progress = 0;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(AppLocalizations.of(context)!
                .updaterNewVersionAvalivable(widget.update.newVersion)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('${widget.update.patchNote}'),
          ),
          if (downloading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: LinearProgressIndicator(
                value: progress,
              ),
            ),
          if (finished)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: LinearProgressIndicator(),
            )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () async {
              final tmpPath =
                  (await getTemporaryDirectory()).path + "/update.apk";
              print(widget.update.downloadUrl);
              final data = await Dio(BaseOptions(headers: {
                'Accept': 'application/octet-stream'
              }, responseType: ResponseType.bytes))
                  .get(widget.update.downloadUrl,
                      onReceiveProgress: (receivedBytes, totalBytes) {
                setState(() {
                  downloading = true;
                  progress = (receivedBytes / totalBytes);
                });
              });
              setState(() {
                downloading = false;
                finished = true;
              });
              print(data.data);
              await File(tmpPath).writeAsBytes(data.data);
              await OpenFile.open(tmpPath);
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.updaterInstallButton))
      ],
    );
  }
}
