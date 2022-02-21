import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:manager_activites/admin/activities/admin_activities.dart';
import 'package:manager_activites/admin/statuses/statuses.dart';
import 'package:manager_activites/contacts/views/detailed_contact.dart';
import 'package:manager_activites/contacts/views/make_new.dart';
import 'package:manager_activites/create_event/create_event.dart';
import 'package:manager_activites/home/view/all_activities_view.dart';
import 'package:manager_activites/home/view/home_view.dart';
import 'package:manager_activites/providers/auth_provider.dart';
import 'package:manager_activites/utils/shake_detector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'login/views/login_view.dart';

class App extends StatelessWidget {
  App({Key? key}) : super(key: key);

  Future<void> _init() async {
    await Firebase.initializeApp();
    if (!kIsWeb) FirebaseMessaging.instance.subscribeToTopic("events_today");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('uk', ''), // Ukrainian, no country code
        Locale('en', ''), // English, no country code
        Locale('ru', ''), // Russian, no country code
      ],
      theme: ThemeData().copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      )),
      home: FutureBuilder(
        future: _init(),
        builder: (context, snapshot) {
          // Check for errors
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return AuthProvider();
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Scaffold();
        },
      ),
      routes: {
        LoginView.route: (BuildContext context) => LoginView(),
        HomeView.route: (BuildContext context) => HomeView(),
        CreateEventView.route: (BuildContext context) => CreateEventView(),
        DetailContactView.route: (BuildContext context) => DetailContactView(),
        AdminActivitiesView.route: (BuildContext context) =>
            AdminActivitiesView(),
        AdminStatusesView.route: (BuildContext context) => AdminStatusesView(),
        ContactCreateView.route: (BuildContext context) => ContactCreateView(),
        AllActivitiesView.route: (BuildContext context) => AllActivitiesView(),
      },
    );
  }
}
