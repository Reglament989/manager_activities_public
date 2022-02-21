import 'package:flutter/material.dart';
import 'package:manager_activites/home/home.dart';
import 'package:manager_activites/login/login.dart';
import 'package:manager_activites/repository/repository.dart';
import 'package:provider/provider.dart';

class AuthProvider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => UserRepository.instance(),
      child: Consumer(
        builder: (context, UserRepository user, _) {
          switch (user.status) {
            case Status.Uninitialized:
              return Scaffold();
            case Status.Unauthenticated:
            case Status.Authenticating:
              return LoginView();
            case Status.Authenticated:
              return HomeView();
          }
        },
      ),
    );
  }
}
