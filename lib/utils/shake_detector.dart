// Dead code

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Shaker {
  Shaker(
      {required this.onPhoneShake,
      this.shakeThresholdGravity = 2,
      this.shakeSlopTimeMS = 500,
      this.shakeCountResetTime = 3000});

  /// User callback for phone shake
  final Future<bool> Function() onPhoneShake;

  /// Shake detection threshold
  final double shakeThresholdGravity;

  /// Minimum time between shake
  final int shakeSlopTimeMS;

  /// Time before shake count resets
  final int shakeCountResetTime;

  int mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int mShakeCount = 0;

  /// StreamSubscription for Accelerometer events
  StreamSubscription? streamSubscription;

  bool isNowProcesed = false;

  void listen() {
    streamSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) async {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double gX = x / 9.80665;
      double gY = y / 9.80665;
      double gZ = z / 9.80665;

      // gForce will be close to 1 when there is no movement.
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > shakeThresholdGravity) {
        var now = DateTime.now().millisecondsSinceEpoch;
        // ignore shake events too close to each other (500ms)
        if (mShakeTimestamp + shakeSlopTimeMS > now) {
          return;
        }

        // reset the shake count after 3 seconds of no shakes
        if (mShakeTimestamp + shakeCountResetTime < now) {
          mShakeCount = 0;
        }

        mShakeTimestamp = now;
        mShakeCount++;

        if (isNowProcesed) return;
        HapticFeedback.vibrate();
        final future = onPhoneShake();
        isNowProcesed = true;
        await future;
        isNowProcesed = false;
      }
    });
  }

  void dispose() {
    streamSubscription?.cancel();
  }
}

class ShakeDetector extends StatefulWidget {
  final Widget child;
  const ShakeDetector({Key? key, required this.child}) : super(key: key);

  @override
  _ShakeDetectorState createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  late final Shaker shaker;

  @override
  void initState() {
    shaker = Shaker(onPhoneShake: () async {
      await showDialog(
          context: context,
          builder: (BuildContext context) => ReportBugDialog());
      return true;
    });
    shaker.listen();
    super.initState();
  }

  @override
  void dispose() {
    shaker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ReportBugDialog extends StatefulWidget {
  const ReportBugDialog({Key? key}) : super(key: key);

  @override
  _ReportBugDialogState createState() => _ReportBugDialogState();
}

class _ReportBugDialogState extends State<ReportBugDialog> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (textController.text.trim().length < 0)
      return Navigator.of(context).pop();
    final domian = "https://stalker-activities.ddns.net:81/report";
    final time = DateTime.now();
    await Dio().post(domian, data: {
      'report': textController.text.trim(),
      'when':
          '${DateFormat(DateFormat.YEAR_NUM_MONTH_WEEKDAY_DAY).format(time)} ${DateFormat(DateFormat.HOUR24_MINUTE).format(time)}'
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Found a bug?'),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8, bottom: 12),
                child: Text('Please describe it in as much detail as possible'),
              ),
              TextField(
                controller: textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: "Whats a problem",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(AppLocalizations.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(AppLocalizations.of(context)!.submitButton),
          onPressed: _submitReport,
        ),
      ],
    );
  }
}
